-- =====================================================================
-- Imagens das atividades · rode este arquivo inteiro UMA vez no Supabase:
-- SQL Editor → New query → cole tudo → Run  (pode rodar de novo sem problema)
--
-- Cria a pasta "atividades" no Storage, onde ficam as folhas (imagens) das
-- atividades em imagem. Assim os dados do painel continuam leves.
--  • Qualquer pessoa com o link consegue VER a imagem (o aluno precisa ver a folha).
--  • Só a conta da Fabi (logada no painel) consegue enviar, trocar ou apagar.
--  • Até 5 MB por imagem, só JPG, PNG ou WEBP (o painel já reduz a imagem antes de enviar).
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('atividades', 'atividades', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "fabi envia imagens" on storage.objects;
create policy "fabi envia imagens" on storage.objects for insert to authenticated
  with check (bucket_id = 'atividades');

drop policy if exists "fabi troca imagens" on storage.objects;
create policy "fabi troca imagens" on storage.objects for update to authenticated
  using (bucket_id = 'atividades' and owner = auth.uid()) with check (bucket_id = 'atividades');

drop policy if exists "fabi apaga imagens" on storage.objects;
create policy "fabi apaga imagens" on storage.objects for delete to authenticated
  using (bucket_id = 'atividades' and owner = auth.uid());
