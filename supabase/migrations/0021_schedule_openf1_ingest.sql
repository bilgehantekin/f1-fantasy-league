-- 0021: OpenF1 sonuç ingest'ini otomatik çalıştır.
--
-- Production setup:
--   select vault.create_secret('https://<project-ref>.supabase.co', 'gridcall_project_url');
--   select vault.create_secret('<SUPABASE_SERVICE_ROLE_KEY>', 'gridcall_service_role_key');
--
-- Job, race_results mevcut olsa bile ingest-openf1'i çağırır; edge function son
-- 72 saatteki yarışları idempotent yeniden çekerek ceza/klasman düzeltmelerini
-- race_results ve race_classifications tablolarına yansıtır.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault cascade;

create or replace function public.invoke_ingest_openf1_cron()
returns bigint
language plpgsql
security definer
set search_path = public, extensions, net, vault
as $$
declare
  v_project_url text;
  v_service_role_key text;
  v_request_id bigint;
begin
  select decrypted_secret
    into v_project_url
  from vault.decrypted_secrets
  where name = 'gridcall_project_url'
  limit 1;

  select decrypted_secret
    into v_service_role_key
  from vault.decrypted_secrets
  where name = 'gridcall_service_role_key'
  limit 1;

  if nullif(v_project_url, '') is null or nullif(v_service_role_key, '') is null then
    raise log 'gridcall-ingest-openf1 skipped: missing Vault secrets gridcall_project_url or gridcall_service_role_key';
    return null;
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/ingest-openf1',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'source', 'pg_cron',
      'scheduled_at', now()
    ),
    timeout_milliseconds := 15000
  )
    into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function public.invoke_ingest_openf1_cron() from public;
grant execute on function public.invoke_ingest_openf1_cron() to postgres;

do $$
begin
  perform cron.unschedule('gridcall-ingest-openf1');
exception
  when others then
    null;
end;
$$;

select cron.schedule(
  'gridcall-ingest-openf1',
  '*/30 * * * *',
  $$select public.invoke_ingest_openf1_cron();$$
);
