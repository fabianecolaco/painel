-- =====================================================================
-- Página do aluno · rode este arquivo inteiro UMA vez no Supabase:
-- SQL Editor → New query → cole tudo → Run  (pode rodar de novo sem problema)
--
-- Como funciona:
--  • O aluno nunca lê a tabela "painel". Ele só chama duas funções,
--    portal_get e portal_post, que exigem o link (token) + PIN de 4 números.
--  • portal_get devolve só o que é dele: atividades, notas, aulas,
--    mensalidades (menos para aluno menor de idade), assuntos e recados marcados como visíveis e a gramática liberada para ele. Nada de observações
--    privadas, telefones, anotações do diário ou dados de outros alunos.
--  • Reposição: o aluno pede quantas quiser enquanto tiver saldo (ajuste + faltas − reposições),
--    com a antecedência mínima de Ajustes (padrão 3 horas);
--    o pedido reserva o horário e a Fabi aceita ou recusa no painel (recusada devolve o crédito).
--  • O que o aluno faz (respostas, tema da página, reposição, prática de vocabulário) vai para a
--    caixa "portal_inbox". O painel da Fabi busca essa caixa, aplica e apaga.
--  • 8 PINs errados em 15 minutos bloqueiam o link por 15 minutos.
-- =====================================================================

create table if not exists public.portal_inbox (
  id       bigserial primary key,
  owner    uuid not null references auth.users(id) on delete cascade,
  aluno_id text not null,
  tipo     text not null check (tipo in ('envio', 'tema', 'reposicao', 'vocab')),
  payload  jsonb not null,
  criado   timestamptz not null default now()
);
-- libera o tipo 'vocab' (prática de vocabulário) em bancos criados antes
alter table public.portal_inbox drop constraint if exists portal_inbox_tipo_check;
alter table public.portal_inbox add constraint portal_inbox_tipo_check check (tipo in ('envio', 'tema', 'reposicao', 'vocab'));
create index if not exists portal_inbox_owner on public.portal_inbox (owner, aluno_id);
alter table public.portal_inbox enable row level security;
drop policy if exists "dona le inbox" on public.portal_inbox;
create policy "dona le inbox" on public.portal_inbox for select to authenticated using (owner = auth.uid());
drop policy if exists "dona apaga inbox" on public.portal_inbox;
create policy "dona apaga inbox" on public.portal_inbox for delete to authenticated using (owner = auth.uid());

create table if not exists public.portal_tentativas (
  token text not null,
  ts    timestamptz not null default now()
);
create index if not exists portal_tentativas_tk on public.portal_tentativas (token, ts);
alter table public.portal_tentativas enable row level security; -- sem regras: só as funções abaixo mexem

-- ---------------------------------------------------------------- PIN
create or replace function public._portal_auth(p_token text, p_pin text,
  out o_owner uuid, out o_aluno jsonb, out o_dados jsonb, out o_erro text)
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  delete from portal_tentativas where ts < now() - interval '1 day';
  select count(*) into n from portal_tentativas where token = left(p_token, 80) and ts > now() - interval '15 minutes';
  if n >= 8 then o_erro := 'bloqueado'; return; end if;

  select p.owner, a.v, p.dados into o_owner, o_aluno, o_dados
    from painel p, jsonb_array_elements(coalesce(p.dados->'alunos', '[]'::jsonb)) a(v)
   where a.v->>'token' = p_token and coalesce(a.v->>'ativo', 'true') <> 'false'
   limit 1;

  if o_aluno is null or coalesce(o_aluno->>'pin', '') = '' or o_aluno->>'pin' is distinct from p_pin then
    insert into portal_tentativas (token) values (left(coalesce(p_token, ''), 80));
    o_owner := null; o_aluno := null; o_dados := null; o_erro := 'pin';
  end if;
end $$;
revoke all on function public._portal_auth(text, text) from public, anon, authenticated;

-- ---------------------------------------------------------------- ler
create or replace function public.portal_get(p_token text, p_pin text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare au record; aid text; d jsonb; env jsonb;
begin
  select * into au from _portal_auth(p_token, p_pin);
  if au.o_erro is not null then return jsonb_build_object('erro', au.o_erro); end if;
  d := au.o_dados; aid := au.o_aluno->>'id';
  env := coalesce((select jsonb_agg(e) from jsonb_array_elements(coalesce(d->'envios', '[]')) e where e->>'aluno' = aid), '[]');

  return jsonb_build_object(
    'aluno', au.o_aluno - array['obs_privada', 'pin', 'tel1', 'tel2', 'resp_nome', 'resp_tel', 'origem', 'indicado_por']
                        - (case when coalesce(au.o_aluno->>'menor', 'false') = 'true' then 'cobranca' else '' end),
    'envios', env,
    'atividades', coalesce((select jsonb_agg(t) from jsonb_array_elements(coalesce(d->'atividades', '[]')) t
                             where exists (select 1 from jsonb_array_elements(env) e where e->>'atividade' = t->>'id')), '[]'),
    -- aluno menor de idade: a mensalidade não vai para a página dele
    'mensalidades', case when coalesce(au.o_aluno->>'menor', 'false') = 'true' then '[]'::jsonb
                    else coalesce((select jsonb_agg(m) from jsonb_array_elements(coalesce(d->'mensalidades', '[]')) m where m->>'aluno' = aid), '[]') end,
    'eventos', coalesce((select jsonb_agg(e - 'obs') from jsonb_array_elements(coalesce(d->'eventos', '[]')) e where e->>'aluno' = aid), '[]'),
    'aulas_publicas', coalesce((select jsonb_agg(x - 'notas') from jsonb_array_elements(coalesce(d->'diario', '[]')) x
                                 where x->>'aluno' = aid and x->>'mostrar' = 'true'), '[]'),
    'ocupado', jsonb_build_object(
      'aulas', coalesce((select jsonb_agg(jsonb_build_object('id', 'o' || md5(x->>'id'), 'aulas', x->'aulas', 'inicio', x->'inicio', 'ativo', x->'ativo'))
                           from jsonb_array_elements(coalesce(d->'alunos', '[]')) x where x->>'id' <> aid), '[]'),
      'eventos', coalesce((select jsonb_agg(z) from (
          select jsonb_build_object('aluno', 'o' || md5(e->>'aluno'), 'data', e->'data', 'hora', e->'hora', 'dur', e->'dur', 'tipo', e->'tipo') z
            from jsonb_array_elements(coalesce(d->'eventos', '[]')) e where e->>'aluno' <> aid and coalesce(e->>'hora', '') <> '' and coalesce(e->>'aprovacao', '') <> 'recusada'
          union all
          select jsonb_build_object('aluno', 'o' || md5(i.aluno_id), 'data', i.payload->'data', 'hora', i.payload->'hora', 'dur', i.payload->'dur', 'tipo', 'reposicao')
            from portal_inbox i where i.owner = au.o_owner and i.tipo = 'reposicao' and i.aluno_id <> aid) q), '[]')),
    'ajustes', jsonb_build_object(
      'pix_chave', d#>'{ajustes,pix_chave}', 'pix_nome', d#>'{ajustes,pix_nome}', 'pix_cidade', d#>'{ajustes,pix_cidade}',
      'telefone', d#>'{ajustes,telefone}', 'obrigado', d#>'{ajustes,obrigado}', 'passo', d#>'{ajustes,passo}',
      'disponibilidade', d#>'{ajustes,disponibilidade}', 'semanas', d#>'{ajustes,semanas}',
      'antecedencia_h', case when jsonb_typeof(d#>'{ajustes,antecedencia_h}') = 'number' then greatest(0, least(168, (d#>>'{ajustes,antecedencia_h}')::numeric))::int else 3 end),
    'gramatica', coalesce((select jsonb_agg(g - 'liberado') from jsonb_array_elements(coalesce(d->'gramatica', '[]')) g
                            where coalesce(g->'liberado', '[]') ? aid), '[]'),
    'vocab', coalesce((select jsonb_agg(v - 'liberado') from jsonb_array_elements(coalesce(d->'vocab', '[]')) v
                        where coalesce(v->'liberado', '[]') ? aid), '[]'),
    'avisos', coalesce((select jsonb_agg(jsonb_build_object('id', v->'id', 'texto', v->'texto', 'criado', v->'criado'))
                          from jsonb_array_elements(coalesce(d->'avisos', '[]')) v
                         where (v->>'alvo' = 'todos' or v->>'alvo' = aid)
                           and (coalesce(v->>'ate', '') = '' or v->>'ate' >= to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM-DD'))), '[]'),
    'inbox', coalesce((select jsonb_agg(jsonb_build_object('tipo', i.tipo, 'payload', i.payload, 'criado', i.criado) order by i.id)
                         from portal_inbox i where i.owner = au.o_owner and i.aluno_id = aid), '[]'),
    'hoje', to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM-DD"T"HH24:MI'));
end $$;

-- ---------------------------------------------------------------- enviar
create or replace function public.portal_post(p_token text, p_pin text, p_tipo text, p_payload jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare au record; aid text; d jsonb; ref text; saldo numeric; dur_aula int; dt date; hr time; du int; st timestamp; agora timestamp; dow int; wk text; av jsonb; foto text; ante int;
begin
  select * into au from _portal_auth(p_token, p_pin);
  if au.o_erro is not null then return jsonb_build_object('erro', au.o_erro); end if;
  d := au.o_dados; aid := au.o_aluno->>'id';
  if (select count(*) from portal_inbox where owner = au.o_owner and aluno_id = aid and criado > now() - interval '1 hour') >= 60 then
    return '{"erro":"limite"}';
  end if;

  if p_tipo = 'envio' then
    if octet_length(p_payload::text) > 100000 then return '{"erro":"grande"}'; end if;
    if not exists (select 1 from jsonb_array_elements(coalesce(d->'envios', '[]')) x
                    where x->>'id' = p_payload->>'envio_id' and x->>'aluno' = aid and x->>'status' = 'pendente') then
      return '{"erro":"envio"}';
    end if;
    if exists (select 1 from portal_inbox where owner = au.o_owner and aluno_id = aid and tipo = 'envio' and payload->>'envio_id' = p_payload->>'envio_id') then
      return '{"erro":"repetido"}';
    end if;
    insert into portal_inbox (owner, aluno_id, tipo, payload)
    values (au.o_owner, aid, 'envio', jsonb_build_object('envio_id', p_payload->>'envio_id', 'respostas', coalesce(p_payload->'respostas', '{}'::jsonb)));

  elsif p_tipo = 'tema' then
    foto := coalesce(p_payload#>>'{tema,foto}', '');
    if octet_length(foto) > 300000 or (foto <> '' and foto not like 'data:image/%') then return '{"erro":"grande"}'; end if;
    delete from portal_inbox where owner = au.o_owner and aluno_id = aid and tipo = 'tema';
    insert into portal_inbox (owner, aluno_id, tipo, payload)
    values (au.o_owner, aid, 'tema', jsonb_build_object('tema', jsonb_build_object(
      'cor', left(coalesce(p_payload#>>'{tema,cor}', '#B88378'), 9), 'fonte', left(coalesce(p_payload#>>'{tema,fonte}', 'Poppins'), 40), 'foto', foto)));

  elsif p_tipo = 'reposicao' then
    perform pg_advisory_xact_lock(hashtext(au.o_owner::text));
    ref := p_payload->>'ref';
    begin dt := (p_payload->>'data')::date; hr := (p_payload->>'hora')::time;
    exception when others then return '{"erro":"horario"}'; end;
    du := coalesce((au.o_aluno#>>'{aulas,0,dur}')::int, 60);
    agora := now() at time zone 'America/Sao_Paulo';

    -- saldo de reposição = ajuste manual + faltas − reposições que contam − pedidos ainda na caixa (sem validade)
    -- uma reposição de 30 min numa aula de 1 h desconta 0,5; "aula perdida" (sem_repor) não gera crédito
    dur_aula := greatest(1, du);
    saldo := (case when jsonb_typeof(au.o_aluno->'repo_extra') = 'number' then round((au.o_aluno->>'repo_extra')::numeric, 2) else 0 end)
           + (select count(*) from jsonb_array_elements(coalesce(d->'eventos', '[]')) x where x->>'aluno' = aid
                and ((x->>'tipo' = 'falta' and coalesce(x->>'sem_repor', 'false') <> 'true') or (x->>'tipo' = 'cancelada' and x->>'repor' = 'true')))
           - coalesce((select sum(case when coalesce(x->>'dur', '') ~ '^\d+$' then round((x->>'dur')::numeric / dur_aula, 2) else 1 end)
                from jsonb_array_elements(coalesce(d->'eventos', '[]')) x where x->>'aluno' = aid and x->>'tipo' = 'reposicao'
                and coalesce(x->>'status', '') <> 'faltou_devolve' and coalesce(x->>'aprovacao', '') <> 'recusada'), 0)
           - coalesce((select sum(case when coalesce(payload->>'dur', '') ~ '^\d+$' then round((payload->>'dur')::numeric / dur_aula, 2) else 1 end)
                from portal_inbox where owner = au.o_owner and aluno_id = aid and tipo = 'reposicao'), 0);
    if saldo <= 0 then return '{"erro":"credito"}'; end if;
    if saldo < 1 then du := greatest(15, round(saldo * dur_aula)::int); end if; -- sobrou meia aula: a reposição é mais curta
    -- a referência (qual aula faltada está sendo reposta): uma data já passada, que ainda não tenha reposição
    if ref is null or ref !~ '^\d{4}-\d{2}-\d{2}$' or ref > to_char(agora::date, 'YYYY-MM-DD')
       or exists (select 1 from jsonb_array_elements(coalesce(d->'eventos', '[]')) x where x->>'aluno' = aid and x->>'tipo' = 'reposicao' and x->>'ref' = ref and coalesce(x->>'aprovacao', '') <> 'recusada')
       or exists (select 1 from portal_inbox where owner = au.o_owner and aluno_id = aid and tipo = 'reposicao' and payload->>'ref' = ref) then
      ref := '';
    end if;

    -- antecedência mínima de Ajustes (padrão 3 horas), no máximo 15 dias à frente
    ante := case when jsonb_typeof(d#>'{ajustes,antecedencia_h}') = 'number' then greatest(0, least(168, (d#>>'{ajustes,antecedencia_h}')::numeric))::int else 3 end;
    st := dt + hr;
    if st < agora + make_interval(hours => ante) or st > agora + interval '15 days' then return '{"erro":"horario"}'; end if;

    -- dentro da disponibilidade (a da semana, se ela editou só aquela semana; senão a padrão)
    dow := extract(dow from dt)::int;
    wk := to_char(dt - (extract(isodow from dt)::int - 1), 'YYYY-MM-DD');
    if d#>array['ajustes', 'semanas', wk] is not null then av := coalesce(d#>array['ajustes', 'semanas', wk, dow::text], '[]');
    else av := coalesce(d#>array['ajustes', 'disponibilidade', dow::text], '[]'); end if;
    if not exists (select 1 from jsonb_array_elements(av) r
                    where hr >= (r->>0)::time and extract(epoch from hr) / 60 + du <= extract(epoch from (r->>1)::time) / 60) then
      return '{"erro":"horario"}';
    end if;

    -- sem conflito com aulas, reposições e extras de ninguém
    if exists (
      with busy as (
        select (s->>'hora')::time h, coalesce((s->>'dur')::int, 60) m
          from jsonb_array_elements(coalesce(d->'alunos', '[]')) a, jsonb_array_elements(coalesce(a->'aulas', '[]')) s
         where coalesce(a->>'ativo', 'true') <> 'false' and (s->>'dia')::int = dow and coalesce(a->>'inicio', '0000') <= dt::text
           and not exists (select 1 from jsonb_array_elements(coalesce(d->'eventos', '[]')) x
                            where x->>'aluno' = a->>'id' and x->>'data' = dt::text and x->>'hora' = s->>'hora' and x->>'tipo' in ('falta', 'cancelada'))
        union all
        select (x->>'hora')::time, coalesce((x->>'dur')::int, 60) from jsonb_array_elements(coalesce(d->'eventos', '[]')) x
         where x->>'data' = dt::text and x->>'tipo' in ('reposicao', 'extra') and coalesce(x->>'hora', '') ~ '^\d{1,2}:\d{2}' and coalesce(x->>'aprovacao', '') <> 'recusada'
        union all
        select (i.payload->>'hora')::time, coalesce((i.payload->>'dur')::int, 60) from portal_inbox i
         where i.owner = au.o_owner and i.tipo = 'reposicao' and i.payload->>'data' = dt::text)
      select 1 from busy
       where extract(epoch from h) / 60 < extract(epoch from hr) / 60 + du
         and extract(epoch from h) / 60 + m > extract(epoch from hr) / 60) then
      return '{"erro":"horario"}';
    end if;

    insert into portal_inbox (owner, aluno_id, tipo, payload)
    values (au.o_owner, aid, 'reposicao', jsonb_build_object('ref', ref, 'data', dt::text, 'hora', to_char(hr, 'HH24:MI'), 'dur', du));
  elsif p_tipo = 'vocab' then
    -- prática de vocabulário: só de um conjunto liberado para este aluno
    if not exists (select 1 from jsonb_array_elements(coalesce(d->'vocab', '[]')) v
                    where v->>'id' = p_payload->>'set' and coalesce(v->'liberado', '[]') ? aid) then
      return '{"erro":"vocab"}';
    end if;
    insert into portal_inbox (owner, aluno_id, tipo, payload)
    values (au.o_owner, aid, 'vocab', jsonb_build_object(
      'set', p_payload->>'set',
      'modo', case when p_payload->>'modo' in ('flash', 'quiz', 'listen', 'match') then p_payload->>'modo' else 'quiz' end,
      'acertos', case when coalesce(p_payload->>'acertos', '') ~ '^\d{1,3}$' then (p_payload->>'acertos')::int else 0 end,
      'total', case when coalesce(p_payload->>'total', '') ~ '^\d{1,3}$' then (p_payload->>'total')::int else 0 end));
  else
    return '{"erro":"tipo"}';
  end if;
  return '{"ok":true}';
end $$;

revoke all on function public.portal_get(text, text) from public;
revoke all on function public.portal_post(text, text, text, jsonb) from public;
grant execute on function public.portal_get(text, text) to anon, authenticated;
grant execute on function public.portal_post(text, text, text, jsonb) to anon, authenticated;
