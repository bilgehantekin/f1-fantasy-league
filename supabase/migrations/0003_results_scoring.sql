-- PitWall — predictions, race_results, lock invariant, scoring, standings

create table public.predictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  race_id uuid not null references public.races(id) on delete cascade,
  winner_driver_id uuid references public.drivers(id),
  p1_id uuid references public.drivers(id),
  p2_id uuid references public.drivers(id),
  p3_id uuid references public.drivers(id),
  pole_driver_id uuid references public.drivers(id),
  fastest_lap_driver_id uuid references public.drivers(id),
  dnf_count smallint check (dnf_count between 0 and 20),
  joker_option text,
  score integer,
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, race_id)
);
create index predictions_race_idx on public.predictions(race_id);
create index predictions_user_idx on public.predictions(user_id);
create trigger predictions_updated_at before update on public.predictions
  for each row execute function public.set_updated_at();

-- Lock invariant: tahminler races.lock_at sonrası yazılamaz (DB-level zorlama)
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
     and new.pole_driver_id is not distinct from old.pole_driver_id
     and new.fastest_lap_driver_id is not distinct from old.fastest_lap_driver_id
     and new.dnf_count is not distinct from old.dnf_count
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
create trigger predictions_enforce_lock
  before insert or update on public.predictions
  for each row execute function public.enforce_prediction_lock();

alter table public.predictions enable row level security;

-- Kendi tahminini her zaman okuyabilirsin
create policy "predictions_read_self" on public.predictions for select using (user_id = auth.uid());

-- Aynı ligdeki kullanıcıların tahminleri ancak kilit sonrası görünür
create policy "predictions_read_after_lock" on public.predictions for select using (
  exists (
    select 1 from public.races r where r.id = predictions.race_id and now() >= r.lock_at
  )
  and public.share_league_with(predictions.user_id)
);

create policy "predictions_insert_self" on public.predictions for insert with check (user_id = auth.uid());
create policy "predictions_update_self" on public.predictions for update using (user_id = auth.uid());

-- Race results
create table public.race_results (
  race_id uuid primary key references public.races(id) on delete cascade,
  p1 uuid not null references public.drivers(id),
  p2 uuid not null references public.drivers(id),
  p3 uuid not null references public.drivers(id),
  pole uuid not null references public.drivers(id),
  fastest_lap uuid not null references public.drivers(id),
  dnf_count smallint not null check (dnf_count between 0 and 20),
  joker_correct text,
  finalized_at timestamptz not null default now()
);
alter table public.race_results enable row level security;
create policy "results_read_all" on public.race_results for select using (true);
-- Yalnızca service role yazar (Edge Function veya admin Studio).

-- Skor formülü (saf SQL, edge function da bunu çağırabilir)
create or replace function public.compute_prediction_score(
  p_pred public.predictions,
  p_res public.race_results,
  p_joker_points integer
) returns integer language plpgsql immutable as $$
declare
  v_score integer := 0;
  v_podium_set uuid[];
  v_pred_podium uuid[];
begin
  if p_pred.winner_driver_id is not null and p_pred.winner_driver_id = p_res.p1 then
    v_score := v_score + 10;
  end if;

  if p_pred.p1_id = p_res.p1 and p_pred.p2_id = p_res.p2 and p_pred.p3_id = p_res.p3 then
    v_score := v_score + 15;
  end if;

  v_podium_set := array[p_res.p1, p_res.p2, p_res.p3];
  v_pred_podium := array[p_pred.p1_id, p_pred.p2_id, p_pred.p3_id];
  for i in 1..3 loop
    if v_pred_podium[i] is not null and v_pred_podium[i] = any(v_podium_set) then
      v_score := v_score + 5;
    end if;
  end loop;

  if p_pred.pole_driver_id is not null and p_pred.pole_driver_id = p_res.pole then
    v_score := v_score + 8;
  end if;

  if p_pred.fastest_lap_driver_id is not null and p_pred.fastest_lap_driver_id = p_res.fastest_lap then
    v_score := v_score + 6;
  end if;

  if p_pred.dnf_count is not null then
    if p_pred.dnf_count = p_res.dnf_count then
      v_score := v_score + 6;
    elsif abs(p_pred.dnf_count - p_res.dnf_count) = 1 then
      v_score := v_score + 3;
    end if;
  end if;

  if p_pred.joker_option is not null and p_res.joker_correct is not null
     and p_pred.joker_option = p_res.joker_correct then
    v_score := v_score + p_joker_points;
  end if;

  return v_score;
end$$;

-- Bir yarış için tüm tahminleri puanla (idempotent)
create or replace function public.score_race(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.race_results;
  v_pred public.predictions;
  v_joker_points smallint;
  v_count int := 0;
begin
  select * into v_res from public.race_results where race_id = p_race_id;
  if not found then return 0; end if;

  select coalesce(points, 12) into v_joker_points
    from public.joker_questions where race_id = p_race_id;
  if v_joker_points is null then v_joker_points := 12; end if;

  for v_pred in select * from public.predictions where race_id = p_race_id loop
    update public.predictions
    set score = public.compute_prediction_score(v_pred, v_res, v_joker_points)
    where id = v_pred.id;
    v_count := v_count + 1;
  end loop;

  update public.races set status = 'finished' where id = p_race_id;
  return v_count;
end$$;

create or replace function public.handle_race_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.score_race(new.race_id);
  return new;
end$$;
create trigger on_race_result_insert
  after insert on public.race_results
  for each row execute function public.handle_race_result();
create trigger on_race_result_update
  after update on public.race_results
  for each row execute function public.handle_race_result();

-- Lig-kapsamlı sıralama RPC'leri (RLS uyumlu — invoker user'ın görebileceği kayıtları görür)
create or replace function public.league_weekly_standings(p_league_id uuid, p_race_id uuid)
returns table(user_id uuid, username text, score int, rnk bigint)
language sql stable security definer set search_path = public as $$
  with members as (
    select user_id from public.league_memberships where league_id = p_league_id
  )
  select p.user_id, pr.username, p.score,
         rank() over (order by p.score desc nulls last)
  from public.predictions p
  join public.profiles pr on pr.id = p.user_id
  join members m on m.user_id = p.user_id
  where p.race_id = p_race_id;
$$;

create or replace function public.league_season_standings(p_league_id uuid, p_season_id smallint)
returns table(user_id uuid, username text, total_score bigint, raced_count bigint, rnk bigint)
language sql stable security definer set search_path = public as $$
  with members as (
    select user_id from public.league_memberships where league_id = p_league_id
  )
  select p.user_id, pr.username,
         sum(coalesce(p.score, 0))::bigint,
         count(p.id) filter (where p.score is not null)::bigint,
         rank() over (order by sum(coalesce(p.score, 0)) desc)
  from public.predictions p
  join public.races r on r.id = p.race_id
  join public.profiles pr on pr.id = p.user_id
  join members m on m.user_id = p.user_id
  where r.season_id = p_season_id
  group by p.user_id, pr.username;
$$;

-- Caller permissions
grant execute on function public.create_league(text, smallint, public.league_type) to authenticated;
grant execute on function public.join_league_by_code(text) to authenticated;
grant execute on function public.league_weekly_standings(uuid, uuid) to authenticated;
grant execute on function public.league_season_standings(uuid, smallint) to authenticated;
grant execute on function public.score_race(uuid) to service_role;
