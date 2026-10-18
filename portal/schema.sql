-- GARI portal authorization bootstrap for a dedicated Supabase project.
-- Run in Supabase SQL editor after enabling email OTP authentication.
-- Default deny: members must be provisioned by a trusted administrator.
create table if not exists public.portal_members (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 role text not null check (role in ('employee','board','officer')),
 active boolean not null default false,
 created_at timestamptz not null default now()
);
alter table public.portal_members enable row level security;
revoke all on public.portal_members from anon;
grant select on public.portal_members to authenticated;
drop policy if exists "members can read own authorized role" on public.portal_members;
create policy "members can read own authorized role"
on public.portal_members for select to authenticated
using (user_id = (select auth.uid()) and active = true);
-- Do NOT create public insert/update/delete policies.
-- Administrators should invite users and assign roles via privileged server-side tools
-- or Supabase dashboard, never from browser-side code.
-- CRITICAL: Also turn OFF automatic email signups or configure invitation-only onboarding
-- before publishing. Any future content tables require their own RLS policies.
