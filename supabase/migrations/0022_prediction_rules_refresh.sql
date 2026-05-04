-- 0022: Main race prediction format refresh.
-- Adds top constructor/team and safety car predictions while keeping legacy
-- fastest_lap columns for backwards compatibility.

alter table public.predictions
  add column if not exists top_team_id uuid references public.teams(id),
  add column if not exists safety_car boolean;

alter table public.race_results
  add column if not exists top_team_id uuid references public.teams(id),
  add column if not exists safety_car boolean not null default false;

create or replace function public.enforce_prediction_lock()
returns trigger language plpgsql as $$
declare
  v_lock_at timestamptz;
begin
  -- Yarış sonrası score/locked_at güncellemeleri muaf (kullanıcı tahmin alanları değişmemişse).
  if TG_OP = 'UPDATE'
     and new.user_id = old.user_id
     and new.race_id = old.race_id
     and new.winner_driver_id is not distinct from old.winner_driver_id
     and new.p1_id is not distinct from old.p1_id
     and new.p2_id is not distinct from old.p2_id
     and new.p3_id is not distinct from old.p3_id
     and new.top_team_id is not distinct from old.top_team_id
     and new.pole_driver_id is not distinct from old.pole_driver_id
     and new.fastest_lap_driver_id is not distinct from old.fastest_lap_driver_id
     and new.dnf_count is not distinct from old.dnf_count
     and new.safety_car is not distinct from old.safety_car
     and new.joker_option is not distinct from old.joker_option then
    return new;
  end if;

  select lock_at into v_lock_at from public.races where id = new.race_id;
  if v_lock_at is null then
    raise exception 'Race % does not exist', new.race_id;
  end if;
  if now() >= v_lock_at then
    raise exception 'Predictions are locked for this race (lock_at=%)', v_lock_at
      using errcode = 'P0001';
  end if;
  if new.p1_id is not null and new.p1_id = new.p2_id then
    raise exception 'P1 and P2 must be different drivers';
  end if;
  if new.p1_id is not null and new.p1_id = new.p3_id then
    raise exception 'P1 and P3 must be different drivers';
  end if;
  if new.p2_id is not null and new.p2_id = new.p3_id then
    raise exception 'P2 and P3 must be different drivers';
  end if;
  return new;
end$$;

create or replace function public.compute_prediction_score(
  p_pred public.predictions,
  p_res public.race_results,
  p_joker_points integer
) returns integer language plpgsql immutable as $$
declare
  v_score integer := 0;
  v_actual_podium uuid[];
  v_pred_podium uuid[];
  v_name_hits integer := 0;
  v_exact_hits integer := 0;
begin
  if p_pred.winner_driver_id is not null and p_pred.winner_driver_id = p_res.p1 then
    v_score := v_score + 10;
  end if;

  v_actual_podium := array[p_res.p1, p_res.p2, p_res.p3];
  v_pred_podium := array[p_pred.p1_id, p_pred.p2_id, p_pred.p3_id];
  for i in 1..3 loop
    if v_pred_podium[i] is not null and v_pred_podium[i] = any(v_actual_podium) then
      v_name_hits := v_name_hits + 1;
      v_score := v_score + 5;
    end if;
    if v_pred_podium[i] is not null and v_pred_podium[i] = v_actual_podium[i] then
      v_exact_hits := v_exact_hits + 1;
      v_score := v_score + 2;
    end if;
  end loop;
  if v_exact_hits = 3 then
    v_score := v_score + 3;
  end if;

  if p_pred.top_team_id is not null and p_pred.top_team_id = p_res.top_team_id then
    v_score := v_score + 10;
  end if;

  if p_pred.pole_driver_id is not null and p_pred.pole_driver_id = p_res.pole then
    v_score := v_score + 8;
  end if;

  if p_pred.dnf_count is not null then
    if p_pred.dnf_count = p_res.dnf_count then
      v_score := v_score + 6;
    elsif abs(p_pred.dnf_count - p_res.dnf_count) = 1 then
      v_score := v_score + 3;
    end if;
  end if;

  if p_pred.safety_car is not null and p_pred.safety_car = p_res.safety_car then
    v_score := v_score + 3;
  end if;

  if p_pred.joker_option is not null and p_res.joker_correct is not null
     and p_pred.joker_option = p_res.joker_correct then
    v_score := v_score + p_joker_points;
  end if;

  return v_score;
end$$;

create or replace function public.evaluate_race_badges(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.race_results;
  v_pred public.predictions;
  v_award int := 0;
  v_id_perfect uuid;
  v_id_bullseye uuid;
  v_id_joker uuid;
  v_id_dnf uuid;
  v_id_pole uuid;
  v_id_fl uuid;
  v_id_winner uuid;
begin
  select * into v_res from public.race_results where race_id = p_race_id;
  if not found then return 0; end if;

  select id into v_id_perfect  from public.badges where code='perfect_week';
  select id into v_id_bullseye from public.badges where code='bullseye_podium';
  select id into v_id_joker    from public.badges where code='joker_master';
  select id into v_id_dnf      from public.badges where code='dnf_oracle';
  select id into v_id_pole     from public.badges where code='pole_caller';
  select id into v_id_fl       from public.badges where code='fastest_caller';
  select id into v_id_winner   from public.badges where code='weekly_winner';

  for v_pred in select * from public.predictions where race_id = p_race_id loop
    if v_id_bullseye is not null
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3 then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_bullseye, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_joker is not null
       and v_pred.joker_option is not null and v_res.joker_correct is not null
       and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_joker, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_dnf is not null
       and v_pred.dnf_count is not null and v_pred.dnf_count = v_res.dnf_count then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_dnf, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_pole is not null
       and v_pred.pole_driver_id = v_res.pole then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_pole, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_fl is not null
       and v_pred.fastest_lap_driver_id = v_res.fastest_lap then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_fl, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_perfect is not null
       and v_pred.winner_driver_id = v_res.p1
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3
       and v_pred.top_team_id is not distinct from v_res.top_team_id
       and v_pred.pole_driver_id = v_res.pole
       and v_pred.dnf_count = v_res.dnf_count
       and v_pred.safety_car is not distinct from v_res.safety_car
       and v_pred.joker_option is not null and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_perfect, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
  end loop;

  insert into public.user_badges (user_id, badge_id, race_id)
  select distinct p.user_id, v_id_winner, p_race_id
  from public.predictions p
  join public.league_memberships m
    on m.user_id = p.user_id
   and m.league_id = p.league_id
  where v_id_winner is not null
    and p.race_id = p_race_id and p.score is not null
    and p.score = (
      select max(p2.score) from public.predictions p2
      where p2.race_id = p_race_id
        and p2.league_id = m.league_id
        and p2.score is not null
    )
  on conflict do nothing;

  return v_award;
end$$;
