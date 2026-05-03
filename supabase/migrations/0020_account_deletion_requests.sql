-- 0020: In-app account deletion request lifecycle.

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'cancelled')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  unique (user_id, status)
);

alter table public.account_deletion_requests enable row level security;

create policy "account_deletion_read_self"
  on public.account_deletion_requests
  for select
  using (auth.uid() = user_id);

create policy "account_deletion_insert_self"
  on public.account_deletion_requests
  for insert
  with check (auth.uid() = user_id);

create or replace function public.request_account_deletion(p_reason text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  insert into public.account_deletion_requests (user_id, reason)
  values (v_user_id, nullif(trim(p_reason), ''))
  on conflict (user_id, status)
  do update set
    reason = coalesce(nullif(trim(excluded.reason), ''), account_deletion_requests.reason),
    requested_at = now()
  returning id into v_request_id;

  return v_request_id;
end;
$$;

grant execute on function public.request_account_deletion(text) to authenticated;
