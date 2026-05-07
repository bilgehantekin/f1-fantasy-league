-- 0039: Yarış sonrası ceza/klasman düzeltmelerini daha uzun pencerede yakala.
--
-- - Var olan 30 dakikalık job son 72 saati sık kontrol eder.
-- - Bu ek job son 7 günü günde 1 kez audit eder.
-- - Edge function artık sprint sonuçlarını da yeniden yazabildiği için audit
--   sprint cezalarını/klasman değişikliklerini de puanlara yansıtır.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault cascade;

create or replace function public.invoke_ingest_openf1_audit_cron()
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
    raise log 'gridcall-ingest-openf1-audit skipped: missing Vault secrets gridcall_project_url or gridcall_service_role_key';
    return null;
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/ingest-openf1',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'source', 'pg_cron_audit',
      'scheduled_at', now(),
      'audit', true,
      'force_sprint', true
    ),
    timeout_milliseconds := 15000
  )
    into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function public.invoke_ingest_openf1_audit_cron() from public;
grant execute on function public.invoke_ingest_openf1_audit_cron() to postgres;

do $$
begin
  perform cron.unschedule('gridcall-ingest-openf1-audit');
exception
  when others then
    null;
end;
$$;

select cron.schedule(
  'gridcall-ingest-openf1-audit',
  '17 6 * * *',
  $$select public.invoke_ingest_openf1_audit_cron();$$
);
