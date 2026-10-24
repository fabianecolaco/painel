-- =====================================================================
-- Imagens e áudios das atividades · rode este arquivo inteiro UMA vez no Supabase:
-- SQL Editor → New query → cole tudo → Run  (pode rodar de novo sem problema)
--
-- Cria a pasta "atividades" no Storage, onde ficam as folhas (imagens) das
-- atividades em imagem. Assim os dados do painel continuam leves.
--  • Qualquer pessoa com o link consegue VER a imagem (o aluno precisa ver a folha).
--  • Só a conta da Fabi (logada no painel) consegue enviar, trocar ou apagar.
--  • Até 25 MB por arquivo: imagens (JPG, PNG, WEBP) e áudios (MP3, M4A, WAV, OGG, WEBM).
--    O painel já reduz a imagem antes de enviar. Se você já rodou a versão antiga, rode de novo.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('atividades', 'atividades', true, 26214400, array['image/jpeg', 'image/png', 'image/webp',
  'audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/x-m4a', 'audio/m4a', 'audio/aac', 'audio/wav', 'audio/x-wav', 'audio/wave', 'audio/ogg', 'audio/webm'])
on conflict (id) do update set public = true, file_size_limit = 26214400, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "fabi envia imagens" on storage.objects;
create policy "fabi envia imagens" on storage.objects for insert to authenticated
  with check (bucket_id = 'atividades');

drop policy if exists "fabi troca imagens" on storage.objects;
create policy "fabi troca imagens" on storage.objects for update to authenticated
  using (bucket_id = 'atividades' and owner = auth.uid()) with check (bucket_id = 'atividades');

drop policy if exists "fabi apaga imagens" on storage.objects;
create policy "fabi apaga imagens" on storage.objects for delete to authenticated
  using (bucket_id = 'atividades' and owner = auth.uid());
