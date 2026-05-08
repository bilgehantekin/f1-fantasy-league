-- Restore API role privileges expected by Supabase/PostgREST.
-- RLS policies still decide which rows each role can access.

begin;

grant usage on schema public to anon, authenticated, service_role;

grant all privileges on all tables in schema public to anon, authenticated, service_role;
grant all privileges on all routines in schema public to anon, authenticated, service_role;
grant all privileges on all sequences in schema public to anon, authenticated, service_role;

alter default privileges in schema public
  grant all privileges on tables to anon, authenticated, service_role;

alter default privileges in schema public
  grant all privileges on routines to anon, authenticated, service_role;

alter default privileges in schema public
  grant all privileges on sequences to anon, authenticated, service_role;

commit;
