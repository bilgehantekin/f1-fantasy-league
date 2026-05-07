-- Cleanup Canadian GP demo data and restore the local upcoming schedule.

begin;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.user_badges ub
using race
where ub.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.predictions p
using race
where p.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.sprint_predictions sp
using race
where sp.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.race_results rr
using race
where rr.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.sprint_results sr
using race
where sr.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.race_classifications rc
using race
where rc.race_id = race.id;

with race as (
  select id
  from public.races
  where season_id = 2026
    and name = 'Canadian Grand Prix'
)
delete from public.sprint_classifications sc
using race
where sc.race_id = race.id;

update public.races
set
  qualifying_at = '2026-05-23 20:00:00+00',
  race_at = '2026-05-24 18:00:00+00',
  status = 'upcoming',
  has_sprint = true,
  sprint_qualifying_at = '2026-05-22 20:00:00+00',
  sprint_race_at = '2026-05-23 16:00:00+00',
  sprint_status = 'upcoming'
where season_id = 2026
  and name = 'Canadian Grand Prix';

commit;

select
  r.name,
  r.status,
  r.sprint_status,
  r.sprint_qualifying_at,
  r.sprint_race_at,
  r.sprint_lock_at,
  r.qualifying_at,
  r.race_at,
  r.lock_at,
  (select count(*) from public.predictions p where p.race_id = r.id) as main_predictions,
  (select count(*) from public.sprint_predictions sp where sp.race_id = r.id) as sprint_predictions,
  (select count(*) from public.race_results rr where rr.race_id = r.id) as main_results,
  (select count(*) from public.sprint_results sr where sr.race_id = r.id) as sprint_results
from public.races r
where r.season_id = 2026
  and r.name = 'Canadian Grand Prix';
