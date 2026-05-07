-- Repair local test data with official 2026 result/classification rows.
--
-- Sources used while preparing this seed:
-- - formula1.com 2026 race result, qualifying, fastest lap and sprint result pages.
--
-- This script intentionally recalculates scores/badges after correcting results.

begin;

alter table public.predictions disable trigger predictions_enforce_lock;
alter table public.sprint_predictions disable trigger sprint_pred_lock;

with target_races as (
  select id
  from public.races
  where season_id = 2026
    and name in (
      'Australian Grand Prix',
      'Chinese Grand Prix',
      'Japanese Grand Prix',
      'Miami Grand Prix'
    )
),
bilge as (
  select id
  from public.profiles
  where lower(username) = 'bilge'
  order by created_at nulls last, id
  limit 1
),
league as (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
),
australia as (
  select id
  from public.races
  where season_id = 2026 and name = 'Australian Grand Prix'
  limit 1
)
delete from public.predictions p
using bilge, league, australia
where p.user_id = bilge.id
  and p.league_id = league.id
  and p.race_id = australia.id;

delete from public.user_badges ub
using public.races r
where ub.race_id = r.id
  and r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  );

delete from public.race_classifications rc
using public.races r
where rc.race_id = r.id
  and r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  );

with rows(name, code, position, status) as (
  values
    ('Australian Grand Prix','RUS',1,'finished'),
    ('Australian Grand Prix','ANT',2,'finished'),
    ('Australian Grand Prix','LEC',3,'finished'),
    ('Australian Grand Prix','HAM',4,'finished'),
    ('Australian Grand Prix','NOR',5,'finished'),
    ('Australian Grand Prix','VER',6,'finished'),
    ('Australian Grand Prix','BEA',7,'finished'),
    ('Australian Grand Prix','LIN',8,'finished'),
    ('Australian Grand Prix','BOR',9,'finished'),
    ('Australian Grand Prix','GAS',10,'finished'),
    ('Australian Grand Prix','OCO',11,'finished'),
    ('Australian Grand Prix','ALB',12,'finished'),
    ('Australian Grand Prix','LAW',13,'finished'),
    ('Australian Grand Prix','COL',14,'finished'),
    ('Australian Grand Prix','SAI',15,'finished'),
    ('Australian Grand Prix','PER',16,'finished'),
    ('Australian Grand Prix','STR',17,'finished'),
    ('Australian Grand Prix','ALO',null,'dnf'),
    ('Australian Grand Prix','BOT',null,'dnf'),
    ('Australian Grand Prix','HAD',null,'dnf'),
    ('Australian Grand Prix','PIA',null,'dns'),
    ('Australian Grand Prix','HUL',null,'dns'),

    ('Chinese Grand Prix','ANT',1,'finished'),
    ('Chinese Grand Prix','RUS',2,'finished'),
    ('Chinese Grand Prix','HAM',3,'finished'),
    ('Chinese Grand Prix','LEC',4,'finished'),
    ('Chinese Grand Prix','BEA',5,'finished'),
    ('Chinese Grand Prix','GAS',6,'finished'),
    ('Chinese Grand Prix','LAW',7,'finished'),
    ('Chinese Grand Prix','HAD',8,'finished'),
    ('Chinese Grand Prix','SAI',9,'finished'),
    ('Chinese Grand Prix','COL',10,'finished'),
    ('Chinese Grand Prix','HUL',11,'finished'),
    ('Chinese Grand Prix','LIN',12,'finished'),
    ('Chinese Grand Prix','BOT',13,'finished'),
    ('Chinese Grand Prix','OCO',14,'finished'),
    ('Chinese Grand Prix','PER',15,'finished'),
    ('Chinese Grand Prix','VER',null,'dnf'),
    ('Chinese Grand Prix','ALO',null,'dnf'),
    ('Chinese Grand Prix','STR',null,'dnf'),
    ('Chinese Grand Prix','PIA',null,'dns'),
    ('Chinese Grand Prix','NOR',null,'dns'),
    ('Chinese Grand Prix','BOR',null,'dns'),
    ('Chinese Grand Prix','ALB',null,'dns'),

    ('Japanese Grand Prix','ANT',1,'finished'),
    ('Japanese Grand Prix','PIA',2,'finished'),
    ('Japanese Grand Prix','LEC',3,'finished'),
    ('Japanese Grand Prix','RUS',4,'finished'),
    ('Japanese Grand Prix','NOR',5,'finished'),
    ('Japanese Grand Prix','HAM',6,'finished'),
    ('Japanese Grand Prix','GAS',7,'finished'),
    ('Japanese Grand Prix','VER',8,'finished'),
    ('Japanese Grand Prix','LAW',9,'finished'),
    ('Japanese Grand Prix','OCO',10,'finished'),
    ('Japanese Grand Prix','HUL',11,'finished'),
    ('Japanese Grand Prix','HAD',12,'finished'),
    ('Japanese Grand Prix','BOR',13,'finished'),
    ('Japanese Grand Prix','LIN',14,'finished'),
    ('Japanese Grand Prix','SAI',15,'finished'),
    ('Japanese Grand Prix','COL',16,'finished'),
    ('Japanese Grand Prix','PER',17,'finished'),
    ('Japanese Grand Prix','ALO',18,'finished'),
    ('Japanese Grand Prix','BOT',19,'finished'),
    ('Japanese Grand Prix','ALB',20,'finished'),
    ('Japanese Grand Prix','STR',null,'dnf'),
    ('Japanese Grand Prix','BEA',null,'dnf'),

    ('Miami Grand Prix','ANT',1,'finished'),
    ('Miami Grand Prix','NOR',2,'finished'),
    ('Miami Grand Prix','PIA',3,'finished'),
    ('Miami Grand Prix','RUS',4,'finished'),
    ('Miami Grand Prix','VER',5,'finished'),
    ('Miami Grand Prix','HAM',6,'finished'),
    ('Miami Grand Prix','COL',7,'finished'),
    ('Miami Grand Prix','LEC',8,'finished'),
    ('Miami Grand Prix','SAI',9,'finished'),
    ('Miami Grand Prix','ALB',10,'finished'),
    ('Miami Grand Prix','BEA',11,'finished'),
    ('Miami Grand Prix','BOR',12,'finished'),
    ('Miami Grand Prix','OCO',13,'finished'),
    ('Miami Grand Prix','LIN',14,'finished'),
    ('Miami Grand Prix','ALO',15,'finished'),
    ('Miami Grand Prix','PER',16,'finished'),
    ('Miami Grand Prix','STR',17,'finished'),
    ('Miami Grand Prix','BOT',18,'finished'),
    ('Miami Grand Prix','HUL',null,'dnf'),
    ('Miami Grand Prix','LAW',null,'dnf'),
    ('Miami Grand Prix','GAS',null,'dnf'),
    ('Miami Grand Prix','HAD',null,'dnf')
)
insert into public.race_classifications (race_id, driver_id, position, status)
select r.id, d.id, rows.position::smallint, rows.status
from rows
join public.races r on r.season_id = 2026 and r.name = rows.name
join public.drivers d on d.season_id = 2026 and d.code = rows.code
on conflict (race_id, driver_id) do update
set position = excluded.position,
    status = excluded.status,
    updated_at = now();

delete from public.sprint_classifications sc
using public.races r
where sc.race_id = r.id
  and r.season_id = 2026
  and r.name in ('Chinese Grand Prix', 'Miami Grand Prix');

with rows(name, code, position, status) as (
  values
    ('Chinese Grand Prix','RUS',1,'finished'),
    ('Chinese Grand Prix','LEC',2,'finished'),
    ('Chinese Grand Prix','HAM',3,'finished'),
    ('Chinese Grand Prix','NOR',4,'finished'),
    ('Chinese Grand Prix','ANT',5,'finished'),
    ('Chinese Grand Prix','PIA',6,'finished'),
    ('Chinese Grand Prix','LAW',7,'finished'),
    ('Chinese Grand Prix','BEA',8,'finished'),
    ('Chinese Grand Prix','VER',9,'finished'),
    ('Chinese Grand Prix','OCO',10,'finished'),
    ('Chinese Grand Prix','GAS',11,'finished'),
    ('Chinese Grand Prix','SAI',12,'finished'),
    ('Chinese Grand Prix','BOR',13,'finished'),
    ('Chinese Grand Prix','COL',14,'finished'),
    ('Chinese Grand Prix','HAD',15,'finished'),
    ('Chinese Grand Prix','ALB',16,'finished'),
    ('Chinese Grand Prix','ALO',17,'finished'),
    ('Chinese Grand Prix','STR',18,'finished'),
    ('Chinese Grand Prix','PER',19,'finished'),
    ('Chinese Grand Prix','HUL',null,'dnf'),
    ('Chinese Grand Prix','BOT',null,'dnf'),
    ('Chinese Grand Prix','LIN',null,'dnf'),

    ('Miami Grand Prix','NOR',1,'finished'),
    ('Miami Grand Prix','PIA',2,'finished'),
    ('Miami Grand Prix','LEC',3,'finished'),
    ('Miami Grand Prix','RUS',4,'finished'),
    ('Miami Grand Prix','VER',5,'finished'),
    ('Miami Grand Prix','ANT',6,'finished'),
    ('Miami Grand Prix','HAM',7,'finished'),
    ('Miami Grand Prix','GAS',8,'finished'),
    ('Miami Grand Prix','HAD',9,'finished'),
    ('Miami Grand Prix','COL',10,'finished'),
    ('Miami Grand Prix','OCO',11,'finished'),
    ('Miami Grand Prix','BEA',12,'finished'),
    ('Miami Grand Prix','SAI',13,'finished'),
    ('Miami Grand Prix','LAW',14,'finished'),
    ('Miami Grand Prix','ALO',15,'finished'),
    ('Miami Grand Prix','PER',16,'finished'),
    ('Miami Grand Prix','STR',17,'finished'),
    ('Miami Grand Prix','ALB',18,'finished'),
    ('Miami Grand Prix','BOT',19,'finished'),
    ('Miami Grand Prix','HUL',null,'dns'),
    ('Miami Grand Prix','BOR',null,'dsq'),
    ('Miami Grand Prix','LIN',null,'dns')
)
insert into public.sprint_classifications (race_id, driver_id, position, status)
select r.id, d.id, rows.position::smallint, rows.status
from rows
join public.races r on r.season_id = 2026 and r.name = rows.name
join public.drivers d on d.season_id = 2026 and d.code = rows.code
on conflict (race_id, driver_id) do update
set position = excluded.position,
    status = excluded.status,
    updated_at = now();

with official(name, pole, fastest_lap, safety_car, top_team) as (
  values
    ('Australian Grand Prix','RUS','VER',false,'MER'),
    ('Chinese Grand Prix','ANT','ANT',false,'MER'),
    ('Japanese Grand Prix','ANT','ANT',false,'MER'),
    ('Miami Grand Prix','ANT','NOR',true,'MER')
),
podiums as (
  select r.id as race_id,
         (max(d.id::text) filter (where rc.position = 1))::uuid as p1,
         (max(d.id::text) filter (where rc.position = 2))::uuid as p2,
         (max(d.id::text) filter (where rc.position = 3))::uuid as p3,
         max(pole_driver.id::text)::uuid as pole,
         max(fl_driver.id::text)::uuid as fastest_lap,
         max(t.id::text)::uuid as top_team_id,
         count(*) filter (where rc.status = 'dnf')::smallint as dnf_count,
         bool_or(o.safety_car) as safety_car
  from official o
  join public.races r on r.season_id = 2026 and r.name = o.name
  join public.race_classifications rc on rc.race_id = r.id
  join public.drivers d on d.id = rc.driver_id
  join public.drivers pole_driver on pole_driver.season_id = 2026 and pole_driver.code = o.pole
  join public.drivers fl_driver on fl_driver.season_id = 2026 and fl_driver.code = o.fastest_lap
  join public.teams t on t.season_id = 2026 and t.code = o.top_team
  group by r.id
)
insert into public.race_results (
  race_id,
  p1,
  p2,
  p3,
  pole,
  fastest_lap,
  top_team_id,
  dnf_count,
  safety_car,
  joker_correct,
  finalized_at
)
select race_id,
       p1,
       p2,
       p3,
       pole,
       fastest_lap,
       top_team_id,
       dnf_count,
       safety_car,
       case when safety_car then 'Evet' else 'Hayır' end,
       now()
from podiums
on conflict (race_id) do update
set p1 = excluded.p1,
    p2 = excluded.p2,
    p3 = excluded.p3,
    pole = excluded.pole,
    fastest_lap = excluded.fastest_lap,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    joker_correct = excluded.joker_correct,
    finalized_at = excluded.finalized_at;

with official(name, pole, safety_car, top_team) as (
  values
    ('Chinese Grand Prix','RUS',false,'FER'),
    ('Miami Grand Prix','NOR',false,'MCL')
),
podiums as (
  select r.id as race_id,
         (max(d.id::text) filter (where sc.position = 1))::uuid as p1,
         (max(d.id::text) filter (where sc.position = 2))::uuid as p2,
         (max(d.id::text) filter (where sc.position = 3))::uuid as p3,
         max(pole_driver.id::text)::uuid as pole,
         max(t.id::text)::uuid as top_team_id,
         count(*) filter (where sc.status = 'dnf')::smallint as dnf_count,
         bool_or(o.safety_car) as safety_car
  from official o
  join public.races r on r.season_id = 2026 and r.name = o.name
  join public.sprint_classifications sc on sc.race_id = r.id
  join public.drivers d on d.id = sc.driver_id
  join public.drivers pole_driver on pole_driver.season_id = 2026 and pole_driver.code = o.pole
  join public.teams t on t.season_id = 2026 and t.code = o.top_team
  group by r.id
)
insert into public.sprint_results (
  race_id,
  p1,
  p2,
  p3,
  pole,
  top_team_id,
  dnf_count,
  safety_car,
  finalized_at
)
select race_id,
       p1,
       p2,
       p3,
       pole,
       top_team_id,
       dnf_count,
       safety_car,
       now()
from podiums
on conflict (race_id) do update
set p1 = excluded.p1,
    p2 = excluded.p2,
    p3 = excluded.p3,
    pole = excluded.pole,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    finalized_at = excluded.finalized_at;

do $$
declare
  v_race record;
begin
  for v_race in
    select id, name, has_sprint
    from public.races
    where season_id = 2026
      and name in (
        'Australian Grand Prix',
        'Chinese Grand Prix',
        'Japanese Grand Prix',
        'Miami Grand Prix'
      )
    order by round
  loop
    perform public.score_race(v_race.id);
    perform public.evaluate_race_badges(v_race.id);
    if v_race.has_sprint then
      perform public.score_sprint(v_race.id);
      perform public.evaluate_sprint_badges(v_race.id);
    end if;
  end loop;
end$$;

alter table public.predictions enable trigger predictions_enforce_lock;
alter table public.sprint_predictions enable trigger sprint_pred_lock;

commit;

select 'Ana yarış sonuç kontrolü' as metrik,
       r.name as gp,
       p1.code as p1,
       p2.code as p2,
       p3.code as p3,
       rr.dnf_count
from public.races r
join public.race_results rr on rr.race_id = r.id
join public.drivers p1 on p1.id = rr.p1
join public.drivers p2 on p2.id = rr.p2
join public.drivers p3 on p3.id = rr.p3
where r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  )
order by r.round;

select 'Klasman satır kontrolü' as metrik,
       r.name as gp,
       count(*)::int as satir
from public.races r
join public.race_classifications rc on rc.race_id = r.id
where r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  )
group by r.round, r.name
order by r.round;

select 'bilge Australian tahmin kontrolü' as metrik,
       count(*)::int as tahmin_sayisi
from public.predictions p
join public.profiles pr on pr.id = p.user_id
join public.races r on r.id = p.race_id
join public.leagues l on l.id = p.league_id
where lower(pr.username) = 'bilge'
  and l.invite_code = 'RS38SVPJ'
  and r.season_id = 2026
  and r.name = 'Australian Grand Prix';
