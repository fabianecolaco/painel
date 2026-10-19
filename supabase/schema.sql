-- =====================================================================
-- Painel Teacher Fabi · rode este arquivo inteiro no Supabase:
-- SQL Editor → New query → cole tudo → Run
-- Guarda todos os dados do painel num único documento por usuária,
-- e só a dona da conta consegue ler ou alterar.
-- =====================================================================
create table if not exists public.painel (
  owner      uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  dados      jsonb not null,
  versao     integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.painel enable row level security;

drop policy if exists "dona le" on public.painel;
create policy "dona le" on public.painel for select to authenticated using (owner = auth.uid());

drop policy if exists "dona cria" on public.painel;
create policy "dona cria" on public.painel for insert to authenticated with check (owner = auth.uid());

drop policy if exists "dona altera" on public.painel;
create policy "dona altera" on public.painel for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
