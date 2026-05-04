-- 0024: Sprint prediction parity, 8-char invite codes, and real 2026 race order.

alter table public.sprint_predictions
  add column if not exists top_team_id uuid references public.teams(id),
  add column if not exists safety_car boolean;

alter table public.sprint_results
  add column if not exists top_team_id uuid references public.teams(id),
  add column if not exists safety_car boolean not null default false;

create or replace function public.assert_sprint_pred_unlocked()
returns trigger language plpgsql as $$
declare
  v_lock_at timestamptz;
  v_has_sprint boolean;
begin
  if TG_OP = 'UPDATE'
     and new.user_id = old.user_id
     and new.race_id = old.race_id
     and new.league_id is not distinct from old.league_id
     and new.winner_driver_id is not distinct from old.winner_driver_id
     and new.p1_id is not distinct from old.p1_id
     and new.p2_id is not distinct from old.p2_id
     and new.p3_id is not distinct from old.p3_id
     and new.top_team_id is not distinct from old.top_team_id
     and new.pole_driver_id is not distinct from old.pole_driver_id
     and new.dnf_count is not distinct from old.dnf_count
     and new.safety_car is not distinct from old.safety_car then
    return new;
  end if;

  select sprint_lock_at, has_sprint
    into v_lock_at, v_has_sprint
    from public.races where id = new.race_id;
  if not coalesce(v_has_sprint, false) then
    raise exception 'No sprint for this race' using errcode = '22023';
  end if;
  if v_lock_at is null then
    raise exception 'Sprint lock_at missing' using errcode = '22023';
  end if;
  if now() >= v_lock_at then
    raise exception 'Sprint predictions are locked' using errcode = '23514';
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
    v_score := v_score + 10;
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
    v_score := v_score + 3;
  end if;

  return v_score;
end$$;

create or replace function public.generate_invite_code()
returns text language plpgsql as $$
declare
  v_code text;
  v_chars constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_attempt int := 0;
begin
  loop
    v_code := '';
    for i in 1..8 loop
      v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
    end loop;
    if not exists (select 1 from public.leagues where invite_code = v_code) then
      return v_code;
    end if;
    v_attempt := v_attempt + 1;
    if v_attempt > 50 then
      raise exception 'Could not generate unique invite code';
    end if;
  end loop;
end$$;

alter table public.leagues
  drop constraint if exists leagues_invite_code_check;

do $$
declare
  v_league record;
  v_code text;
begin
  for v_league in select id from public.leagues loop
    v_code := public.generate_invite_code();
    update public.leagues set invite_code = v_code where id = v_league.id;
  end loop;
end$$;

alter table public.leagues
  add constraint leagues_invite_code_check check (char_length(invite_code) = 8);

delete from public.races
where season_id = 2026
  and status = 'cancelled'::public.race_status;

update public.races
set round = round + 1000
where season_id = 2026;

with ordered as (
  select id, row_number() over (order by race_at) as new_round
  from public.races
  where season_id = 2026
)
update public.races r
set round = ordered.new_round
from ordered
where ordered.id = r.id;
