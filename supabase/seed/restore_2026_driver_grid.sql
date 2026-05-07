-- Restore the full 2026 local test driver grid after a local reset.

begin;

insert into public.teams (season_id, code, name, color)
values
  (2026, 'RBR', 'Red Bull Racing', '#3671C6'),
  (2026, 'MCL', 'McLaren', '#FF8000'),
  (2026, 'FER', 'Ferrari', '#E80020'),
  (2026, 'MER', 'Mercedes', '#27F4D2'),
  (2026, 'AST', 'Aston Martin', '#229971'),
  (2026, 'WIL', 'Williams', '#64C4FF'),
  (2026, 'ALP', 'Alpine', '#0093CC'),
  (2026, 'HAA', 'Haas', '#B6BABD'),
  (2026, 'RB', 'Racing Bulls', '#6692FF'),
  (2026, 'AUD', 'Audi', '#C8002D'),
  (2026, 'CAD', 'Cadillac', '#D4AF37')
on conflict (season_id, code) do update
set name = excluded.name,
    color = excluded.color;

with team_ids as (
  select code, id
  from public.teams
  where season_id = 2026
)
insert into public.drivers (season_id, code, full_name, number, team_id)
values
  (2026, 'VER', 'Max Verstappen', 3, (select id from team_ids where code = 'RBR')),
  (2026, 'ANT', 'Kimi Antonelli', 12, (select id from team_ids where code = 'MER')),
  (2026, 'NOR', 'Lando Norris', 1, (select id from team_ids where code = 'MCL')),
  (2026, 'PIA', 'Oscar Piastri', 81, (select id from team_ids where code = 'MCL')),
  (2026, 'LEC', 'Charles Leclerc', 16, (select id from team_ids where code = 'FER')),
  (2026, 'HAM', 'Lewis Hamilton', 44, (select id from team_ids where code = 'FER')),
  (2026, 'RUS', 'George Russell', 63, (select id from team_ids where code = 'MER')),
  (2026, 'ALO', 'Fernando Alonso', 14, (select id from team_ids where code = 'AST')),
  (2026, 'SAI', 'Carlos Sainz', 55, (select id from team_ids where code = 'WIL')),
  (2026, 'ALB', 'Alexander Albon', 23, (select id from team_ids where code = 'WIL')),
  (2026, 'BEA', 'Oliver Bearman', 87, (select id from team_ids where code = 'HAA')),
  (2026, 'BOR', 'Gabriel Bortoleto', 5, (select id from team_ids where code = 'AUD')),
  (2026, 'BOT', 'Valtteri Bottas', 77, (select id from team_ids where code = 'CAD')),
  (2026, 'COL', 'Franco Colapinto', 43, (select id from team_ids where code = 'ALP')),
  (2026, 'GAS', 'Pierre Gasly', 10, (select id from team_ids where code = 'ALP')),
  (2026, 'HAD', 'Isack Hadjar', 6, (select id from team_ids where code = 'RBR')),
  (2026, 'HUL', 'Nico Hulkenberg', 27, (select id from team_ids where code = 'AUD')),
  (2026, 'LAW', 'Liam Lawson', 30, (select id from team_ids where code = 'RB')),
  (2026, 'LIN', 'Arvid Lindblad', 41, (select id from team_ids where code = 'RB')),
  (2026, 'OCO', 'Esteban Ocon', 31, (select id from team_ids where code = 'HAA')),
  (2026, 'PER', 'Sergio Perez', 11, (select id from team_ids where code = 'CAD')),
  (2026, 'STR', 'Lance Stroll', 18, (select id from team_ids where code = 'AST'))
on conflict (season_id, code) do update
set full_name = excluded.full_name,
    number = excluded.number,
    team_id = excluded.team_id;

commit;

select '2026 drivers' as metrik, count(*)::int as adet
from public.drivers
where season_id = 2026;
