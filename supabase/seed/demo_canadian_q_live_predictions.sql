-- Demo: Canadian GP Q live scenario.
-- - Arkadaşlar Ligi'ndeki tüm kullanıcılara sprint + ana yarış tahmini ekler.
-- - Canadian sprint sonucunu tamamlanmış kabul edip sprint tahminlerini skorlar.
-- - Ana yarış tahminleri kayıtlı kalır, ana yarış sonucu eklenmez.

begin;

alter table public.predictions disable trigger predictions_enforce_lock;
alter table public.sprint_predictions disable trigger sprint_pred_lock;

with
  ctx as (
    select
      l.id as league_id,
      r.id as race_id
    from public.leagues l
    cross join public.races r
    where l.invite_code = 'RS38SVPJ'
      and r.season_id = 2026
      and r.name = 'Canadian Grand Prix'
    limit 1
  ),
  d as (
    select
      (array_agg(id) filter (where code = 'NOR'))[1] as nor,
      (array_agg(id) filter (where code = 'PIA'))[1] as pia,
      (array_agg(id) filter (where code = 'LEC'))[1] as lec,
      (array_agg(id) filter (where code = 'VER'))[1] as ver,
      (array_agg(id) filter (where code = 'RUS'))[1] as rus,
      (array_agg(id) filter (where code = 'HAM'))[1] as ham,
      (array_agg(id) filter (where code = 'ANT'))[1] as ant,
      (array_agg(id) filter (where code = 'HAD'))[1] as had,
      (array_agg(id) filter (where code = 'BOR'))[1] as bor,
      (array_agg(id) filter (where code = 'HUL'))[1] as hul,
      (array_agg(id) filter (where code = 'ALO'))[1] as alo,
      (array_agg(id) filter (where code = 'SAI'))[1] as sai
    from public.drivers
    where season_id = 2026
  ),
  t as (
    select
      (array_agg(id) filter (where code = 'MCL'))[1] as mcl,
      (array_agg(id) filter (where code = 'FER'))[1] as fer,
      (array_agg(id) filter (where code = 'RBR'))[1] as rbr,
      (array_agg(id) filter (where code = 'MER'))[1] as mer
    from public.teams
    where season_id = 2026
  ),
  members as (
    select
      p.id as user_id,
      p.username,
      row_number() over (order by p.username) as rn
    from public.profiles p
    join public.league_memberships lm on lm.user_id = p.id
    join ctx on ctx.league_id = lm.league_id
  ),
  sprint_plan as (
    select
      members.user_id,
      members.username,
      ctx.race_id,
      ctx.league_id,
      case (members.rn - 1) % 5
        when 0 then d.nor when 1 then d.pia when 2 then d.lec
        when 3 then d.ver else d.rus
      end as winner_driver_id,
      case (members.rn - 1) % 5
        when 0 then d.nor when 1 then d.pia when 2 then d.nor
        when 3 then d.ver else d.lec
      end as p1_id,
      case (members.rn - 1) % 5
        when 0 then d.pia when 1 then d.nor when 2 then d.pia
        when 3 then d.nor else d.rus
      end as p2_id,
      case (members.rn - 1) % 5
        when 0 then d.lec when 1 then d.lec when 2 then d.ver
        when 3 then d.pia else d.ham
      end as p3_id,
      case (members.rn - 1) % 5
        when 0 then d.nor when 1 then d.pia when 2 then d.lec
        when 3 then d.ver else d.rus
      end as pole_driver_id,
      case (members.rn - 1) % 4
        when 0 then t.mcl when 1 then t.mcl when 2 then t.fer else t.rbr
      end as top_team_id,
      case (members.rn - 1) % 3
        when 0 then 0 when 1 then 1 else 2
      end as dnf_count,
      (members.rn % 2 = 0) as safety_car
    from members
    cross join ctx
    cross join d
    cross join t
  )
insert into public.sprint_predictions (
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  top_team_id,
  dnf_count,
  safety_car
)
select
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  top_team_id,
  dnf_count,
  safety_car
from sprint_plan
on conflict (user_id, race_id, league_id) do update
set winner_driver_id = excluded.winner_driver_id,
    p1_id = excluded.p1_id,
    p2_id = excluded.p2_id,
    p3_id = excluded.p3_id,
    pole_driver_id = excluded.pole_driver_id,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    score = null,
    updated_at = now();

with
  ctx as (
    select
      l.id as league_id,
      r.id as race_id
    from public.leagues l
    cross join public.races r
    where l.invite_code = 'RS38SVPJ'
      and r.season_id = 2026
      and r.name = 'Canadian Grand Prix'
    limit 1
  ),
  d as (
    select
      (array_agg(id) filter (where code = 'NOR'))[1] as nor,
      (array_agg(id) filter (where code = 'PIA'))[1] as pia,
      (array_agg(id) filter (where code = 'LEC'))[1] as lec,
      (array_agg(id) filter (where code = 'VER'))[1] as ver,
      (array_agg(id) filter (where code = 'RUS'))[1] as rus,
      (array_agg(id) filter (where code = 'HAM'))[1] as ham,
      (array_agg(id) filter (where code = 'ANT'))[1] as ant,
      (array_agg(id) filter (where code = 'HAD'))[1] as had,
      (array_agg(id) filter (where code = 'BOR'))[1] as bor,
      (array_agg(id) filter (where code = 'HUL'))[1] as hul,
      (array_agg(id) filter (where code = 'ALO'))[1] as alo,
      (array_agg(id) filter (where code = 'SAI'))[1] as sai
    from public.drivers
    where season_id = 2026
  ),
  t as (
    select
      (array_agg(id) filter (where code = 'MCL'))[1] as mcl,
      (array_agg(id) filter (where code = 'FER'))[1] as fer,
      (array_agg(id) filter (where code = 'RBR'))[1] as rbr,
      (array_agg(id) filter (where code = 'MER'))[1] as mer
    from public.teams
    where season_id = 2026
  ),
  members as (
    select
      p.id as user_id,
      p.username,
      row_number() over (order by p.username) as rn
    from public.profiles p
    join public.league_memberships lm on lm.user_id = p.id
    join ctx on ctx.league_id = lm.league_id
  ),
  main_plan as (
    select
      members.user_id,
      members.username,
      ctx.race_id,
      ctx.league_id,
      case (members.rn - 1) % 6
        when 0 then d.pia when 1 then d.nor when 2 then d.ver
        when 3 then d.lec when 4 then d.rus else d.ham
      end as winner_driver_id,
      case (members.rn - 1) % 6
        when 0 then d.pia when 1 then d.nor when 2 then d.ver
        when 3 then d.lec when 4 then d.rus else d.ham
      end as p1_id,
      case (members.rn - 1) % 6
        when 0 then d.nor when 1 then d.pia when 2 then d.nor
        when 3 then d.pia when 4 then d.lec else d.rus
      end as p2_id,
      case (members.rn - 1) % 6
        when 0 then d.lec when 1 then d.ver when 2 then d.rus
        when 3 then d.nor when 4 then d.ham else d.ant
      end as p3_id,
      case (members.rn - 1) % 5
        when 0 then d.nor when 1 then d.pia when 2 then d.ver
        when 3 then d.lec else d.rus
      end as pole_driver_id,
      case (members.rn - 1) % 5
        when 0 then d.pia when 1 then d.nor when 2 then d.lec
        when 3 then d.rus else d.ver
      end as fastest_lap_driver_id,
      case (members.rn - 1) % 4
        when 0 then t.mcl when 1 then t.rbr when 2 then t.fer else t.mer
      end as top_team_id,
      case (members.rn - 1) % 4
        when 0 then 1 when 1 then 0 when 2 then 2 else 3
      end as dnf_count,
      (members.rn % 2 = 1) as safety_car
    from members
    cross join ctx
    cross join d
    cross join t
  )
insert into public.predictions (
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  fastest_lap_driver_id,
  top_team_id,
  dnf_count,
  safety_car
)
select
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  fastest_lap_driver_id,
  top_team_id,
  dnf_count,
  safety_car
from main_plan
on conflict (user_id, race_id, league_id) do update
set winner_driver_id = excluded.winner_driver_id,
    p1_id = excluded.p1_id,
    p2_id = excluded.p2_id,
    p3_id = excluded.p3_id,
    pole_driver_id = excluded.pole_driver_id,
    fastest_lap_driver_id = excluded.fastest_lap_driver_id,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    score = null,
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
    select code, id
    from public.drivers
    where season_id = 2026
  ),
  order_seed(code, pos, status) as (
    values
      ('NOR', 1, 'finished'),
      ('PIA', 2, 'finished'),
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
      ('COL', 22, 'finished')
  )
insert into public.sprint_classifications (race_id, driver_id, position, status)
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
      (array_agg(id) filter (where code = 'NOR'))[1] as nor,
      (array_agg(id) filter (where code = 'PIA'))[1] as pia,
      (array_agg(id) filter (where code = 'LEC'))[1] as lec
    from public.drivers
    where season_id = 2026
  ),
  t as (
    select (array_agg(id) filter (where code = 'MCL'))[1] as mcl
    from public.teams
    where season_id = 2026
  )
insert into public.sprint_results (
  race_id,
  p1,
  p2,
  p3,
  pole,
  top_team_id,
  dnf_count,
  safety_car
)
select ctx.race_id, d.nor, d.pia, d.lec, d.nor, t.mcl, 0, false
from ctx
cross join d
cross join t
on conflict (race_id) do update
set p1 = excluded.p1,
    p2 = excluded.p2,
    p3 = excluded.p3,
    pole = excluded.pole,
    top_team_id = excluded.top_team_id,
    dnf_count = excluded.dnf_count,
    safety_car = excluded.safety_car,
    finalized_at = now();

update public.races
set sprint_status = 'finished',
    status = 'upcoming'
where season_id = 2026
  and name = 'Canadian Grand Prix';

alter table public.sprint_predictions enable trigger sprint_pred_lock;
alter table public.predictions enable trigger predictions_enforce_lock;

commit;

select
  p.username,
  sp.score as sprint_score,
  sp.dnf_count as sprint_dnf,
  mp.score as main_score
from public.profiles p
join public.league_memberships lm on lm.user_id = p.id
join public.leagues l on l.id = lm.league_id
join public.races r on r.season_id = 2026 and r.name = 'Canadian Grand Prix'
left join public.sprint_predictions sp
  on sp.user_id = p.id and sp.race_id = r.id and sp.league_id = l.id
left join public.predictions mp
  on mp.user_id = p.id and mp.race_id = r.id and mp.league_id = l.id
where l.invite_code = 'RS38SVPJ'
order by sp.score desc nulls last, p.username;
