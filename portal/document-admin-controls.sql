-- Run once in Supabase SQL Editor to enable GARI administrator Move/Delete.
-- Existing document rows and stored files are preserved.
drop policy if exists "gari_documents_admin_update" on public.gari_documents;
create policy "gari_documents_admin_update" on public.gari_documents
for update to authenticated
using (exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin'))
with check (exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin'));
grant update on public.gari_documents to authenticated;

drop policy if exists "gari_storage_admin_update" on storage.objects;
create policy "gari_storage_admin_update" on storage.objects
for update to authenticated
using (bucket_id='gari-documents' and exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin'))
with check (bucket_id='gari-documents' and exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin'));
