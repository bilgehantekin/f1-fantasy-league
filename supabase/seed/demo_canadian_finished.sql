-- Demo: Canadian GP finished scenario.
-- Keeps sprint results, adds/finalizes the main race result, scores main
-- predictions, and moves Canadian GP into the previous-race state.

begin;

with
  ctx as (
    select id as race_id
    from public.races
    where season_id = 2026
      and name = 'Canadian Grand Prix'
    limit 1
  ),
  d as (
    select code, id
    from public.drivers
    where season_id = 2026
  ),
  order_seed(code, pos, status) as (
    values
      ('PIA', 1, 'finished'),
      ('NOR', 2, 'finished'),
      ('LEC', 3, 'finished'),
      ('VER', 4, 'finished'),
      ('RUS', 5, 'finished'),
      ('HAM', 6, 'finished'),
      ('ANT', 7, 'finished'),
      ('HAD', 8, 'finished'),
      ('ALO', 9, 'finished'),
      ('SAI', 10, 'finished'),
      ('ALB', 11, 'finished'),
      ('GAS', 12, 'finished'),
      ('BOR', 13, 'finished'),
      ('HUL', 14, 'finished'),
      ('LAW', 15, 'finished'),
      ('LIN', 16, 'finished'),
      ('OCO', 17, 'finished'),
      ('BEA', 18, 'finished'),
      ('BOT', 19, 'finished'),
      ('PER', 20, 'finished'),
      ('STR', 21, 'finished'),
      ('COL', null, 'dnf')
  )
insert into public.race_classifications (race_id, driver_id, position, status)
select ctx.race_id, d.id, order_seed.pos, order_seed.status
from ctx
join order_seed on true
join d on d.code = order_seed.code
on conflict (race_id, driver_id) do update
set position = excluded.position,
    status = excluded.status,
    updated_at = now();

with
  ctx as (
    select id as race_id
    from public.races
    where season_id = 2026
      and name = 'Canadian Grand Prix'
    limit 1
  ),
  d as (
    select
      (array_agg(id) filter (where code = 'PIA'))[1] as pia,
      (array_agg(id) filter (where code = 'NOR'))[1] as nor,
      (array_agg(id) filter (where code = 'LEC'))[1] as lec,
      (array_agg(id) filter (where code = 'RUS'))[1] as rus
    from public.drivers
    where season_id = 2026
  ),
  t as (
    select (array_agg(id) filter (where code = 'MCL'))[1] as mcl
    from public.teams
    where season_id = 2026
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
  safety_car
)
select ctx.race_id, d.pia, d.nor, d.lec, d.nor, d.rus, t.mcl, 1, true
from ctx
cross join d
cross join t
on conflict (race_id) do update
set p1 = excluded.p1,
    p2 = excluded.p2,
    p3 = excluded.p3,
    pole = excluded.pole,
    fastest_lap = excluded.fastest_lap,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    finalized_at = now();

update public.races
set status = 'finished',
    sprint_status = 'finished'
where season_id = 2026
  and name = 'Canadian Grand Prix';

commit;

select
  p.username,
  sp.score as sprint_score,
  mp.score as main_score,
  coalesce(sp.score, 0) + coalesce(mp.score, 0) as weekend_score
from public.profiles p
join public.league_memberships lm on lm.user_id = p.id
join public.leagues l on l.id = lm.league_id
join public.races r on r.season_id = 2026 and r.name = 'Canadian Grand Prix'
left join public.sprint_predictions sp
  on sp.user_id = p.id and sp.race_id = r.id and sp.league_id = l.id
left join public.predictions mp
  on mp.user_id = p.id and mp.race_id = r.id and mp.league_id = l.id
where l.invite_code = 'RS38SVPJ'
order by weekend_score desc, p.username;
