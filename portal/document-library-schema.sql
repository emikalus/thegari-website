-- GARI private document library. Run in Supabase SQL Editor as project owner.
create extension if not exists pgcrypto;
insert into storage.buckets (id,name,public,file_size_limit)
values ('gari-documents','gari-documents',false,26214400)
on conflict (id) do update set public=false;

create table if not exists public.gari_documents (
 id uuid primary key default gen_random_uuid(),
 folder text not null check (folder in ('01','02','03','04','05','06','07')),
 title text not null,
 filename text not null,
 object_path text unique not null,
 lifecycle text not null check (lifecycle in ('Official','Adopted','Submitted','Working Draft','Superseded')),
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create index if not exists gari_documents_folder_idx on public.gari_documents(folder);
alter table public.gari_documents enable row level security;

drop policy if exists "gari_documents_read" on public.gari_documents;
create policy "gari_documents_read" on public.gari_documents
for select to authenticated using (
 exists (select 1 from public.portal_members m
 where m.user_id=(select auth.uid()) and m.active=true
 and (m.role='admin'
 or (m.role in ('board','officer') and folder in ('01','02','04','05','06','07'))
 or (m.role='employee' and folder in ('04','05','06','07'))))
);
drop policy if exists "gari_documents_admin_insert" on public.gari_documents;
create policy "gari_documents_admin_insert" on public.gari_documents
for insert to authenticated with check (
 created_by=(select auth.uid()) and exists
 (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin')
);
drop policy if exists "gari_documents_admin_delete" on public.gari_documents;
create policy "gari_documents_admin_delete" on public.gari_documents
for delete to authenticated using (
 exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin')
);
grant select, insert, delete on public.gari_documents to authenticated;

drop policy if exists "gari_storage_read" on storage.objects;
create policy "gari_storage_read" on storage.objects
for select to authenticated using (
 bucket_id='gari-documents' and (
 exists (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin')
 or exists (select 1 from public.gari_documents d where d.object_path=name)
 ));
drop policy if exists "gari_storage_admin_upload" on storage.objects;
create policy "gari_storage_admin_upload" on storage.objects
for insert to authenticated with check (
 bucket_id='gari-documents' and exists
 (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin')
);
drop policy if exists "gari_storage_admin_delete" on storage.objects;
create policy "gari_storage_admin_delete" on storage.objects
for delete to authenticated using (
 bucket_id='gari-documents' and exists
 (select 1 from public.portal_members m where m.user_id=(select auth.uid()) and m.active and m.role='admin')
);
