-- 0028: Account deletion goes from "request" to actual data wipe.
--
-- Adds:
--   * scheduled_for column on account_deletion_requests (now() + grace period)
--   * grace_period_days helper (defaults to 30 days, App Store + privacy aligned)
--   * process_account_deletion(user_id) — security definer function that wipes
--     the user's GridCall data (predictions, sprint predictions, league
--     memberships, user_badges, profile, deletion request rows). Auth user is
--     left to the edge function which calls auth.admin.deleteUser via the
--     service role key.
--   * find_processable_deletion_requests() — returns request rows whose grace
--     period has passed and which are still pending.
--   * complete_deletion_request(request_id) — marks a request completed.
--   * pg_cron schedule that calls the delete-accounts edge function once a day.
--
-- Premium hardening: revoke dev_toggle_premium from authenticated so the RPC
-- cannot be invoked from the client even if a paywall ever ships in dev again.

revoke execute on function public.dev_toggle_premium() from authenticated;

-- Grace period column. Old rows default to 30 days from requested_at.
alter table public.account_deletion_requests
  add column if not exists scheduled_for timestamptz;

update public.account_deletion_requests
set scheduled_for = requested_at + interval '30 days'
where scheduled_for is null;

-- Re-create the request function so new rows get a scheduled_for value and
-- so users can re-trigger the request without losing the original schedule.
-- Drop first because the return signature changes from uuid to table.
drop function if exists public.request_account_deletion(text);

create function public.request_account_deletion(p_reason text default null)
returns table (request_id uuid, scheduled_for timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
  v_scheduled_for timestamptz;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  insert into public.account_deletion_requests (user_id, reason, scheduled_for)
  values (v_user_id, nullif(trim(p_reason), ''), now() + interval '30 days')
  on conflict (user_id, status)
  do update set
    reason = coalesce(nullif(trim(excluded.reason), ''), account_deletion_requests.reason),
    requested_at = now(),
    scheduled_for = coalesce(account_deletion_requests.scheduled_for, excluded.scheduled_for)
  returning id, account_deletion_requests.scheduled_for
    into v_id, v_scheduled_for;

  return query select v_id, v_scheduled_for;
end;
$$;

grant execute on function public.request_account_deletion(text) to authenticated;

-- Wipes the GridCall-owned data for a user. Auth row deletion happens in the
-- edge function (needs service-role admin API).
create or replace function public.process_account_deletion(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    raise exception 'p_user_id required';
  end if;

  -- Predictions and sprint predictions (lock trigger blocks updates after
  -- lock; deletes are not blocked, so we drop them in both tables).
  delete from public.predictions where user_id = p_user_id;
  delete from public.sprint_predictions where user_id = p_user_id;

  -- League memberships. Owned leagues are reassigned or removed depending on
  -- whether anyone else is a member.
  delete from public.league_members where user_id = p_user_id;

  delete from public.leagues l
  where l.owner_id = p_user_id
    and not exists (select 1 from public.league_members m where m.league_id = l.id);

  update public.leagues l
  set owner_id = (
    select m.user_id
    from public.league_members m
    where m.league_id = l.id
    order by m.joined_at asc
    limit 1
  )
  where l.owner_id = p_user_id;

  -- Achievements and notification prefs (table existence varies across
  -- environments — guard with to_regclass).
  if to_regclass('public.user_badges') is not null then
    execute 'delete from public.user_badges where user_id = $1' using p_user_id;
  end if;

  if to_regclass('public.notification_preferences') is not null then
    execute 'delete from public.notification_preferences where user_id = $1' using p_user_id;
  end if;

  -- Premium subscriptions (free tier app, but old rows may exist).
  if to_regclass('public.subscriptions') is not null then
    execute 'delete from public.subscriptions where user_id = $1' using p_user_id;
  end if;

  -- Profile last so foreign keys are clean.
  delete from public.profiles where id = p_user_id;
end;
$$;

revoke all on function public.process_account_deletion(uuid) from public;
grant execute on function public.process_account_deletion(uuid) to service_role;

-- Returns pending requests whose grace period has elapsed.
create or replace function public.find_processable_deletion_requests()
returns table (
  id uuid,
  user_id uuid,
  scheduled_for timestamptz
)
language sql
security definer
set search_path = public
as $$
  select id, user_id, scheduled_for
  from public.account_deletion_requests
  where status = 'pending'
    and scheduled_for is not null
    and scheduled_for <= now()
  order by scheduled_for asc
  limit 50;
$$;

revoke all on function public.find_processable_deletion_requests() from public;
grant execute on function public.find_processable_deletion_requests() to service_role;

create or replace function public.complete_deletion_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.account_deletion_requests
  set status = 'completed',
      processed_at = now()
  where id = p_request_id;
end;
$$;

revoke all on function public.complete_deletion_request(uuid) from public;
grant execute on function public.complete_deletion_request(uuid) to service_role;

-- Daily cron: invoke the delete-accounts edge function. Reuses the same Vault
-- secrets as the OpenF1 ingest cron.
create or replace function public.invoke_delete_accounts_cron()
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
    raise log 'gridcall-delete-accounts skipped: missing Vault secrets';
    return null;
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/delete-accounts',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'source', 'pg_cron',
      'scheduled_at', now()
    ),
    timeout_milliseconds := 30000
  )
    into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function public.invoke_delete_accounts_cron() from public;
grant execute on function public.invoke_delete_accounts_cron() to postgres;

do $$
begin
  perform cron.unschedule('gridcall-delete-accounts');
exception
  when others then
    null;
end;
$$;

select cron.schedule(
  'gridcall-delete-accounts',
  '0 3 * * *',
  $$select public.invoke_delete_accounts_cron();$$
);
