-- 0025: Sprint point tuning, DNF cap 22, and Miami backfill for the
-- prediction fields added after the old draft format.

alter table public.predictions
  drop constraint if exists predictions_dnf_count_check;
alter table public.predictions
  add constraint predictions_dnf_count_check check (dnf_count between 0 and 22);

alter table public.race_results
  drop constraint if exists race_results_dnf_count_check;
alter table public.race_results
  add constraint race_results_dnf_count_check check (dnf_count between 0 and 22);

alter table public.sprint_predictions
  drop constraint if exists sprint_predictions_dnf_count_check;
alter table public.sprint_predictions
  add constraint sprint_predictions_dnf_count_check check (dnf_count between 0 and 22);

alter table public.sprint_results
  drop constraint if exists sprint_results_dnf_count_check;
alter table public.sprint_results
  add constraint sprint_results_dnf_count_check check (dnf_count between 0 and 22);

create or replace function public.compute_sprint_score(
  p_pred public.sprint_predictions,
  p_res public.sprint_results
) returns integer language plpgsql immutable as $$
declare
  v_score integer := 0;
  v_podium_set uuid[];
  v_pred_podium uuid[];
begin
  if p_pred.winner_driver_id is not null and p_pred.winner_driver_id = p_res.p1 then
    v_score := v_score + 8;
  end if;

  if p_pred.p1_id = p_res.p1 and p_pred.p2_id = p_res.p2 and p_pred.p3_id = p_res.p3 then
    v_score := v_score + 12;
  end if;

  v_podium_set := array[p_res.p1, p_res.p2, p_res.p3];
  v_pred_podium := array[p_pred.p1_id, p_pred.p2_id, p_pred.p3_id];
  for i in 1..3 loop
    if v_pred_podium[i] is not null and v_pred_podium[i] = any(v_podium_set) then
      v_score := v_score + 4;
    end if;
  end loop;

  if p_pred.top_team_id is not null and p_pred.top_team_id = p_res.top_team_id then
    v_score := v_score + 8;
  end if;

  if p_pred.pole_driver_id is not null and p_pred.pole_driver_id = p_res.pole then
    v_score := v_score + 6;
  end if;

  if p_pred.dnf_count is not null then
    if p_pred.dnf_count = p_res.dnf_count then
      v_score := v_score + 4;
    elsif abs(p_pred.dnf_count - p_res.dnf_count) = 1 then
      v_score := v_score + 2;
    end if;
  end if;

  if p_pred.safety_car is not null and p_pred.safety_car = p_res.safety_car then
    v_score := v_score + 2;
  end if;

  return v_score;
end$$;

with miami as (
  select id from public.races
  where season_id = 2026 and name = 'Miami Grand Prix'
  limit 1
),
main_team_points as (
  select rc.race_id, d.team_id,
         sum(case rc.position
           when 1 then 25
           when 2 then 18
           when 3 then 15
           when 4 then 12
           when 5 then 10
           when 6 then 8
           when 7 then 6
           when 8 then 4
           when 9 then 2
           when 10 then 1
           else 0
         end)::int as points
  from public.race_classifications rc
  join public.drivers d on d.id = rc.driver_id
  join miami on miami.id = rc.race_id
  where d.team_id is not null
  group by rc.race_id, d.team_id
),
main_best_team as (
  select distinct on (race_id) race_id, team_id
  from main_team_points
  order by race_id, points desc, team_id
)
update public.race_results rr
set top_team_id = coalesce(rr.top_team_id, main_best_team.team_id)
from main_best_team
where rr.race_id = main_best_team.race_id;

with miami as (
  select id from public.races
  where season_id = 2026 and name = 'Miami Grand Prix'
  limit 1
),
sprint_team_points as (
  select sc.race_id, d.team_id,
         sum(case sc.position
           when 1 then 8
           when 2 then 7
           when 3 then 6
           when 4 then 5
           when 5 then 4
           when 6 then 3
           when 7 then 2
           when 8 then 1
           else 0
         end)::int as points
  from public.sprint_classifications sc
  join public.drivers d on d.id = sc.driver_id
  join miami on miami.id = sc.race_id
  where d.team_id is not null
  group by sc.race_id, d.team_id
),
sprint_best_team as (
  select distinct on (race_id) race_id, team_id
  from sprint_team_points
  order by race_id, points desc, team_id
)
update public.sprint_results sr
set top_team_id = coalesce(sr.top_team_id, sprint_best_team.team_id)
from sprint_best_team
where sr.race_id = sprint_best_team.race_id;

alter table public.predictions disable trigger predictions_enforce_lock;
alter table public.sprint_predictions disable trigger sprint_pred_lock;

with miami as (
  select id from public.races
  where season_id = 2026 and name = 'Miami Grand Prix'
  limit 1
)
update public.predictions p
set top_team_id = coalesce(p.top_team_id, rr.top_team_id),
    safety_car = coalesce(p.safety_car, rr.safety_car),
    joker_option = coalesce(p.joker_option, rr.joker_correct)
from miami
join public.race_results rr on rr.race_id = miami.id
where p.race_id = miami.id;

with miami as (
  select id from public.races
  where season_id = 2026 and name = 'Miami Grand Prix'
  limit 1
)
update public.sprint_predictions sp
set top_team_id = coalesce(sp.top_team_id, sr.top_team_id),
    safety_car = coalesce(sp.safety_car, sr.safety_car)
from miami
join public.sprint_results sr on sr.race_id = miami.id
where sp.race_id = miami.id;

alter table public.predictions enable trigger predictions_enforce_lock;
alter table public.sprint_predictions enable trigger sprint_pred_lock;

do $$
declare
  v_miami uuid;
begin
  select id into v_miami
  from public.races
  where season_id = 2026 and name = 'Miami Grand Prix'
  limit 1;

  if v_miami is not null then
    perform public.score_race(v_miami);
    perform public.score_sprint(v_miami);
  end if;
end$$;
