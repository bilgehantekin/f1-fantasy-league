-- 2026 grid uses Audi instead of Sauber. Keep historical seasons untouched.

begin;

with audi as (
  select id
  from public.teams
  where season_id = 2026 and code = 'AUD'
  limit 1
),
sauber as (
  select id
  from public.teams
  where season_id = 2026 and code = 'SAU'
  limit 1
)
update public.drivers d
set team_id = audi.id
from audi, sauber
where d.season_id = 2026
  and d.team_id = sauber.id;

with audi as (
  select id
  from public.teams
  where season_id = 2026 and code = 'AUD'
  limit 1
),
sauber as (
  select id
  from public.teams
  where season_id = 2026 and code = 'SAU'
  limit 1
)
update public.predictions p
set top_team_id = audi.id
from audi, sauber
where p.top_team_id = sauber.id;

with audi as (
  select id
  from public.teams
  where season_id = 2026 and code = 'AUD'
  limit 1
),
sauber as (
  select id
  from public.teams
  where season_id = 2026 and code = 'SAU'
  limit 1
)
update public.sprint_predictions p
set top_team_id = audi.id
from audi, sauber
where p.top_team_id = sauber.id;

with audi as (
  select id
  from public.teams
  where season_id = 2026 and code = 'AUD'
  limit 1
),
sauber as (
  select id
  from public.teams
  where season_id = 2026 and code = 'SAU'
  limit 1
)
update public.race_results r
set top_team_id = audi.id
from audi, sauber
where r.top_team_id = sauber.id;

with audi as (
  select id
  from public.teams
  where season_id = 2026 and code = 'AUD'
  limit 1
),
sauber as (
  select id
  from public.teams
  where season_id = 2026 and code = 'SAU'
  limit 1
)
update public.sprint_results r
set top_team_id = audi.id
from audi, sauber
where r.top_team_id = sauber.id;

delete from public.teams
where season_id = 2026 and code = 'SAU';

commit;
