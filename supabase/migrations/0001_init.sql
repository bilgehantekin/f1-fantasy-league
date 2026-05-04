-- GridCall — foundations: profiles, seasons, teams, drivers, races, joker questions

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end$$;

-- Profiles (1-1 with auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 24),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
create policy "profiles_read_all" on public.profiles for select using (true);
create policy "profiles_insert_self" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_self" on public.profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_username text;
begin
  v_username := coalesce(
    nullif(new.raw_user_meta_data->>'username', ''),
    'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
  );
  insert into public.profiles (id, username)
  values (new.id, v_username)
  on conflict (id) do nothing;
  return new;
end$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Seasons
create table public.seasons (
  id smallint primary key,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.seasons enable row level security;
create policy "seasons_read_all" on public.seasons for select using (true);

-- Teams (sezona bağlı — transferler için)
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  season_id smallint not null references public.seasons(id) on delete cascade,
  code text not null,
  name text not null,
  color text,
  created_at timestamptz not null default now(),
  unique(season_id, code)
);
alter table public.teams enable row level security;
create policy "teams_read_all" on public.teams for select using (true);

-- Drivers
create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  season_id smallint not null references public.seasons(id) on delete cascade,
  code text not null,
  full_name text not null,
  number smallint,
  team_id uuid references public.teams(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(season_id, code)
);
create index drivers_season_team_idx on public.drivers(season_id, team_id);
alter table public.drivers enable row level security;
create policy "drivers_read_all" on public.drivers for select using (true);

-- Races
create type public.race_status as enum ('upcoming','locked','live','finished');

create table public.races (
  id uuid primary key default gen_random_uuid(),
  season_id smallint not null references public.seasons(id) on delete cascade,
  round smallint not null,
  name text not null,
  circuit text not null,
  qualifying_at timestamptz not null,
  race_at timestamptz not null,
  -- Lock tahmin penceresini qualifying'den 1 saat önce kapatır (trigger ile doldurulur).
  lock_at timestamptz not null,
  status public.race_status not null default 'upcoming',
  created_at timestamptz not null default now(),
  unique(season_id, round)
);
create index races_lock_at_idx on public.races(lock_at);
create index races_season_round_idx on public.races(season_id, round);

create or replace function public.set_race_lock_at()
returns trigger language plpgsql as $$
begin
  new.lock_at := new.qualifying_at - interval '1 hour';
  return new;
end$$;
create trigger races_set_lock_at
  before insert or update of qualifying_at on public.races
  for each row execute function public.set_race_lock_at();

alter table public.races enable row level security;
create policy "races_read_all" on public.races for select using (true);

-- Joker questions (haftaya özel editöryal soru)
create table public.joker_questions (
  id uuid primary key default gen_random_uuid(),
  race_id uuid not null references public.races(id) on delete cascade,
  text text not null,
  options jsonb not null,
  correct_option text,
  points smallint not null default 12,
  created_at timestamptz not null default now(),
  unique(race_id)
);
alter table public.joker_questions enable row level security;
create policy "joker_read_all" on public.joker_questions for select using (true);
