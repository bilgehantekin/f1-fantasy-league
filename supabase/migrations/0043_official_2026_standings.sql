create table if not exists public.official_driver_standings (
  season_id integer not null,
  position integer not null,
  driver_code text not null,
  driver_name text not null,
  team_name text not null,
  team_color text,
  points integer not null,
  source_url text not null default 'https://www.formula1.com/en/results/2026/drivers',
  synced_at timestamptz not null default now(),
  primary key (season_id, driver_code)
);

create table if not exists public.official_constructor_standings (
  season_id integer not null,
  position integer not null,
  team_name text not null,
  team_color text,
  points integer not null,
  source_url text not null default 'https://www.formula1.com/en/results/2026/team',
  synced_at timestamptz not null default now(),
  primary key (season_id, team_name)
);

alter table public.official_driver_standings enable row level security;
alter table public.official_constructor_standings enable row level security;

drop policy if exists "official_driver_standings_select" on public.official_driver_standings;
create policy "official_driver_standings_select"
on public.official_driver_standings
for select
using (true);

drop policy if exists "official_constructor_standings_select" on public.official_constructor_standings;
create policy "official_constructor_standings_select"
on public.official_constructor_standings
for select
using (true);

grant select on public.official_driver_standings to anon, authenticated;
grant select on public.official_constructor_standings to anon, authenticated;
grant all on public.official_driver_standings to service_role;
grant all on public.official_constructor_standings to service_role;

delete from public.official_driver_standings where season_id = 2026;
delete from public.official_constructor_standings where season_id = 2026;

insert into public.official_driver_standings
  (season_id, position, driver_code, driver_name, team_name, team_color, points, synced_at)
values
  (2026, 1, 'ANT', 'Kimi Antonelli', 'Mercedes', '#00D7B6', 100, now()),
  (2026, 2, 'RUS', 'George Russell', 'Mercedes', '#00D7B6', 80, now()),
  (2026, 3, 'LEC', 'Charles Leclerc', 'Ferrari', '#ED1131', 59, now()),
  (2026, 4, 'NOR', 'Lando Norris', 'McLaren', '#F47600', 51, now()),
  (2026, 5, 'HAM', 'Lewis Hamilton', 'Ferrari', '#ED1131', 51, now()),
  (2026, 6, 'PIA', 'Oscar Piastri', 'McLaren', '#F47600', 43, now()),
  (2026, 7, 'VER', 'Max Verstappen', 'Red Bull Racing', '#4781D7', 26, now()),
  (2026, 8, 'BEA', 'Oliver Bearman', 'Haas F1 Team', '#9C9FA2', 17, now()),
  (2026, 9, 'GAS', 'Pierre Gasly', 'Alpine', '#00A1E8', 16, now()),
  (2026, 10, 'LAW', 'Liam Lawson', 'Racing Bulls', '#6C98FF', 10, now()),
  (2026, 11, 'COL', 'Franco Colapinto', 'Alpine', '#00A1E8', 7, now()),
  (2026, 12, 'LIN', 'Arvid Lindblad', 'Racing Bulls', '#6C98FF', 4, now()),
  (2026, 13, 'HAD', 'Isack Hadjar', 'Red Bull Racing', '#4781D7', 4, now()),
  (2026, 14, 'SAI', 'Carlos Sainz', 'Williams', '#1868DB', 4, now()),
  (2026, 15, 'BOR', 'Gabriel Bortoleto', 'Audi', '#F50537', 2, now()),
  (2026, 16, 'OCO', 'Esteban Ocon', 'Haas F1 Team', '#9C9FA2', 1, now()),
  (2026, 17, 'ALB', 'Alexander Albon', 'Williams', '#1868DB', 1, now()),
  (2026, 18, 'HUL', 'Nico Hulkenberg', 'Audi', '#F50537', 0, now()),
  (2026, 19, 'BOT', 'Valtteri Bottas', 'Cadillac', '#909090', 0, now()),
  (2026, 20, 'PER', 'Sergio Perez', 'Cadillac', '#909090', 0, now()),
  (2026, 21, 'ALO', 'Fernando Alonso', 'Aston Martin', '#229971', 0, now()),
  (2026, 22, 'STR', 'Lance Stroll', 'Aston Martin', '#229971', 0, now());

insert into public.official_constructor_standings
  (season_id, position, team_name, team_color, points, synced_at)
values
  (2026, 1, 'Mercedes', '#00D7B6', 180, now()),
  (2026, 2, 'Ferrari', '#ED1131', 110, now()),
  (2026, 3, 'McLaren', '#F47600', 94, now()),
  (2026, 4, 'Red Bull Racing', '#4781D7', 30, now()),
  (2026, 5, 'Alpine', '#00A1E8', 23, now()),
  (2026, 6, 'Haas F1 Team', '#9C9FA2', 18, now()),
  (2026, 7, 'Racing Bulls', '#6C98FF', 14, now()),
  (2026, 8, 'Williams', '#1868DB', 5, now()),
  (2026, 9, 'Audi', '#F50537', 2, now()),
  (2026, 10, 'Cadillac', '#909090', 0, now()),
  (2026, 11, 'Aston Martin', '#229971', 0, now());
