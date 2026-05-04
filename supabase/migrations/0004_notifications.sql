-- GridCall — bildirim log tablosu (idempotent reminder göndermek için)

create table public.notifications_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  race_id uuid not null references public.races(id) on delete cascade,
  kind text not null check (kind in ('reminder_6h','reminder_1h','race_start','score_ready')),
  channel text not null check (channel in ('email','push')),
  sent_at timestamptz not null default now(),
  unique(user_id, race_id, kind, channel)
);
create index notifications_log_user_idx on public.notifications_log(user_id, sent_at desc);

alter table public.notifications_log enable row level security;
create policy "notifications_read_self" on public.notifications_log for select using (user_id = auth.uid());
-- Sadece service role yazar.

-- Edge Function (service role) auth.users'a doğrudan REST ile erişemiyor;
-- bu RPC verilen user_id listelerinin email'lerini güvenli şekilde döner.
create or replace function public.get_user_emails(p_ids uuid[])
returns table(id uuid, email text)
language sql security definer set search_path = public, auth stable as $$
  select u.id, u.email::text from auth.users u where u.id = any(p_ids);
$$;
revoke all on function public.get_user_emails(uuid[]) from public;
grant execute on function public.get_user_emails(uuid[]) to service_role;
