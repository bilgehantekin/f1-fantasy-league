-- Store real OpenF1 weekend sessions so race cards can render start lights
-- from actual practice / sprint / qualifying / race schedule data.
create table if not exists public.race_sessions (
  id uuid primary key default gen_random_uuid(),
  race_id uuid not null references public.races(id) on delete cascade,
  session_key bigint unique,
  session_name text not null,
  session_type text not null,
  short_label text not null,
  sort_order smallint not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  source text not null default 'openf1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (race_id, short_label)
);

create index if not exists race_sessions_race_sort_idx
  on public.race_sessions(race_id, sort_order);

alter table public.race_sessions enable row level security;

create policy "race_sessions_read_all"
  on public.race_sessions
  for select
  using (true);
