-- 0015: Tahminleri lig bazında ayır.
-- Önceden bir kullanıcının bir yarış için tek tahmini vardı; artık aynı yarış
-- farklı liglerde farklı tahminlere sahip olabilir.

alter table public.predictions
  add column if not exists league_id uuid references public.leagues(id) on delete cascade;

create temporary table _prediction_leagues on commit drop as
select
  p.id as prediction_id,
  m.league_id,
  row_number() over (partition by p.id order by m.joined_at, m.league_id) as rn
from public.predictions p
join public.league_memberships m on m.user_id = p.user_id;

alter table public.predictions disable trigger predictions_enforce_lock;

update public.predictions p
set league_id = pl.league_id
from _prediction_leagues pl
where pl.prediction_id = p.id
  and pl.rn = 1
  and p.league_id is null;

insert into public.predictions (
  user_id,
  race_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  fastest_lap_driver_id,
  dnf_count,
  joker_option,
  score,
  locked_at,
  created_at,
  updated_at,
  league_id
)
select
  p.user_id,
  p.race_id,
  p.winner_driver_id,
  p.p1_id,
  p.p2_id,
  p.p3_id,
  p.pole_driver_id,
  p.fastest_lap_driver_id,
  p.dnf_count,
  p.joker_option,
  p.score,
  p.locked_at,
  p.created_at,
  p.updated_at,
  pl.league_id
from public.predictions p
join _prediction_leagues pl on pl.prediction_id = p.id
where pl.rn > 1
on conflict do nothing;

alter table public.predictions enable trigger predictions_enforce_lock;

delete from public.predictions where league_id is null;

alter table public.predictions
  alter column league_id set not null;

alter table public.predictions
  drop constraint if exists predictions_user_id_race_id_key;

alter table public.predictions
  add constraint predictions_user_race_league_key unique (user_id, race_id, league_id);

create index if not exists predictions_league_race_idx
  on public.predictions(league_id, race_id);

drop policy if exists "predictions_read_self" on public.predictions;
drop policy if exists "predictions_read_after_lock" on public.predictions;
drop policy if exists "predictions_insert_self" on public.predictions;
drop policy if exists "predictions_update_self" on public.predictions;

create policy "predictions_read_self" on public.predictions
  for select using (
    user_id = auth.uid()
    and public.is_member_of(league_id)
  );

create policy "predictions_read_after_lock" on public.predictions
  for select using (
    exists (
      select 1
      from public.races r
      where r.id = predictions.race_id
        and now() >= r.lock_at
    )
    and public.is_member_of(predictions.league_id)
  );

create policy "predictions_insert_self" on public.predictions
  for insert with check (
    user_id = auth.uid()
    and public.is_member_of(league_id)
  );

create policy "predictions_update_self" on public.predictions
  for update using (
    user_id = auth.uid()
    and public.is_member_of(league_id)
  ) with check (
    user_id = auth.uid()
    and public.is_member_of(league_id)
  );

alter table public.sprint_predictions
  add column if not exists league_id uuid references public.leagues(id) on delete cascade;

create temporary table _sprint_prediction_leagues on commit drop as
select
  p.id as prediction_id,
  m.league_id,
  row_number() over (partition by p.id order by m.joined_at, m.league_id) as rn
from public.sprint_predictions p
join public.league_memberships m on m.user_id = p.user_id;

alter table public.sprint_predictions disable trigger sprint_pred_lock;

update public.sprint_predictions p
set league_id = pl.league_id
from _sprint_prediction_leagues pl
where pl.prediction_id = p.id
  and pl.rn = 1
  and p.league_id is null;

insert into public.sprint_predictions (
  user_id,
  race_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  pole_driver_id,
  dnf_count,
  score,
  created_at,
  updated_at,
  league_id
)
select
  p.user_id,
  p.race_id,
  p.winner_driver_id,
  p.p1_id,
  p.p2_id,
  p.p3_id,
  p.pole_driver_id,
  p.dnf_count,
  p.score,
  p.created_at,
  p.updated_at,
  pl.league_id
from public.sprint_predictions p
join _sprint_prediction_leagues pl on pl.prediction_id = p.id
where pl.rn > 1
on conflict do nothing;

alter table public.sprint_predictions enable trigger sprint_pred_lock;

delete from public.sprint_predictions where league_id is null;

alter table public.sprint_predictions
  alter column league_id set not null;

alter table public.sprint_predictions
  drop constraint if exists sprint_predictions_user_id_race_id_key;

alter table public.sprint_predictions
  add constraint sprint_predictions_user_race_league_key unique (user_id, race_id, league_id);

create index if not exists sprint_predictions_league_race_idx
  on public.sprint_predictions(league_id, race_id);

drop policy if exists "sprint_pred_owner_select" on public.sprint_predictions;
drop policy if exists "sprint_pred_owner_insert" on public.sprint_predictions;
drop policy if exists "sprint_pred_owner_update" on public.sprint_predictions;
drop policy if exists "sprint_pred_owner_delete" on public.sprint_predictions;
drop policy if exists "sprint_pred_league_select" on public.sprint_predictions;

create policy "sprint_pred_owner_select" on public.sprint_predictions
  for select using (
    auth.uid() = user_id
    and public.is_member_of(league_id)
  );

create policy "sprint_pred_owner_insert" on public.sprint_predictions
  for insert with check (
    auth.uid() = user_id
    and public.is_member_of(league_id)
  );

create policy "sprint_pred_owner_update" on public.sprint_predictions
  for update using (
    auth.uid() = user_id
    and public.is_member_of(league_id)
  ) with check (
    auth.uid() = user_id
    and public.is_member_of(league_id)
  );

create policy "sprint_pred_owner_delete" on public.sprint_predictions
  for delete using (
    auth.uid() = user_id
    and public.is_member_of(league_id)
  );

create policy "sprint_pred_league_select" on public.sprint_predictions
  for select using (public.is_member_of(league_id));

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
  where p.race_id = p_race_id
    and p.league_id = p_league_id;
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
    and p.league_id = p_league_id
  group by p.user_id, pr.username;
$$;

create or replace function public.league_weekly_summary(p_league_id uuid, p_race_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with member_predictions as (
    select p.*, pr.username
    from public.predictions p
    join public.league_memberships m
      on m.user_id = p.user_id
     and m.league_id = p_league_id
    join public.profiles pr on pr.id = p.user_id
    where p.league_id = p_league_id
      and p.race_id = p_race_id
      and public.is_member_of(p_league_id)
  ), standings as (
    select user_id, username, coalesce(score, 0) as score,
           rank() over (order by score desc nulls last) as rank
    from member_predictions
    where score is not null
  ), best_prediction as (
    select user_id, username, score
    from standings
    order by score desc, username
    limit 1
  ), joker_hits as (
    select count(*)::int as count
    from member_predictions p
    join public.race_results rr on rr.race_id = p.race_id
    where p.joker_option is not null
      and rr.joker_correct is not null
      and p.joker_option = rr.joker_correct
  ), picks as (
    select winner_driver_id as driver_id from member_predictions where winner_driver_id is not null
    union all select p1_id from member_predictions where p1_id is not null
    union all select p2_id from member_predictions where p2_id is not null
    union all select p3_id from member_predictions where p3_id is not null
    union all select pole_driver_id from member_predictions where pole_driver_id is not null
    union all select fastest_lap_driver_id from member_predictions where fastest_lap_driver_id is not null
  ), most_picked as (
    select d.id, d.code, d.full_name, t.color, count(*)::int as pick_count
    from picks
    join public.drivers d on d.id = picks.driver_id
    left join public.teams t on t.id = d.team_id
    group by d.id, d.code, d.full_name, t.color
    order by count(*) desc, d.code
    limit 1
  ), top_rows as (
    select coalesce(jsonb_agg(jsonb_build_object(
      'user_id', user_id,
      'username', username,
      'score', score,
      'rank', rank
    ) order by rank, username), '[]'::jsonb) as rows
    from (select * from standings order by rank, username limit 5) s
  )
  select jsonb_build_object(
    'best_prediction', coalesce((select to_jsonb(best_prediction) from best_prediction), '{}'::jsonb),
    'joker_hit_count', coalesce((select count from joker_hits), 0),
    'most_picked_driver', coalesce((select to_jsonb(most_picked) from most_picked), '{}'::jsonb),
    'top_standings', (select rows from top_rows),
    'prediction_count', (select count(*) from member_predictions)
  );
$$;
