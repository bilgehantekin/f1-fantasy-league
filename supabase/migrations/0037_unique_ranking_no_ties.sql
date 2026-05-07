-- 0037: Eşit puanda sıralama tekrarını önle.
-- rank() → row_number() ile her kullanıcı benzersiz sıra alır;
-- tiebreak olarak lower(username) asc kullanılmaya devam eder.

create or replace function public.league_season_standings(
  p_league_id uuid,
  p_season_id smallint
) returns table(
  user_id uuid,
  username text,
  total_score bigint,
  raced_count bigint,
  rnk bigint
)
language sql stable security definer set search_path = public as $$
  with members as (
    select m.user_id, pr.username
    from public.league_memberships m
    join public.profiles pr on pr.id = m.user_id
    where m.league_id = p_league_id
  ),
  main_scores as (
    select p.user_id,
           sum(coalesce(p.score, 0))::bigint as total,
           count(p.id) filter (where p.score is not null)::bigint as raced
    from public.predictions p
    join public.races r on r.id = p.race_id
    where p.league_id = p_league_id
      and r.season_id = p_season_id
    group by p.user_id
  ),
  sprint_scores as (
    select sp.user_id,
           sum(coalesce(sp.score, 0))::bigint as total,
           count(sp.id) filter (where sp.score is not null)::bigint as raced
    from public.sprint_predictions sp
    join public.races r on r.id = sp.race_id
    where sp.league_id = p_league_id
      and r.season_id = p_season_id
    group by sp.user_id
  )
  select m.user_id,
         m.username,
         (coalesce(ms.total, 0) + coalesce(ss.total, 0))::bigint as total_score,
         (coalesce(ms.raced, 0) + coalesce(ss.raced, 0))::bigint as raced_count,
         row_number() over (
           order by (coalesce(ms.total, 0) + coalesce(ss.total, 0)) desc,
                    lower(m.username) asc
         ) as rnk
  from members m
  left join main_scores ms on ms.user_id = m.user_id
  left join sprint_scores ss on ss.user_id = m.user_id;
$$;

create or replace function public.league_weekly_standings(
  p_league_id uuid,
  p_race_id uuid,
  p_sprint boolean
) returns table(
  user_id uuid,
  username text,
  score int,
  rnk bigint
)
language sql stable security definer set search_path = public as $$
  with members as (
    select m.user_id, pr.username
    from public.league_memberships m
    join public.profiles pr on pr.id = m.user_id
    where m.league_id = p_league_id
  ),
  scored as (
    select user_id, score
    from public.predictions
    where race_id = p_race_id
      and league_id = p_league_id
      and not p_sprint
    union all
    select user_id, score
    from public.sprint_predictions
    where race_id = p_race_id
      and league_id = p_league_id
      and p_sprint
  )
  select m.user_id,
         m.username,
         s.score,
         row_number() over (
           order by s.score desc nulls last,
                    lower(m.username) asc
         ) as rnk
  from members m
  left join scored s on s.user_id = m.user_id;
$$;

create or replace function public.league_season_standings_before(
  p_league_id uuid,
  p_season_id smallint,
  p_cutoff timestamptz
) returns table(
  user_id uuid,
  username text,
  total_score bigint,
  raced_count bigint,
  rnk bigint
)
language sql stable security definer set search_path = public as $$
  with members as (
    select m.user_id, pr.username
    from public.league_memberships m
    join public.profiles pr on pr.id = m.user_id
    where m.league_id = p_league_id
  ),
  main_scores as (
    select p.user_id,
           sum(coalesce(p.score, 0))::bigint as total,
           count(p.id) filter (where p.score is not null)::bigint as raced
    from public.predictions p
    join public.races r on r.id = p.race_id
    where p.league_id = p_league_id
      and r.season_id = p_season_id
      and r.race_at < p_cutoff
    group by p.user_id
  ),
  sprint_scores as (
    select sp.user_id,
           sum(coalesce(sp.score, 0))::bigint as total,
           count(sp.id) filter (where sp.score is not null)::bigint as raced
    from public.sprint_predictions sp
    join public.races r on r.id = sp.race_id
    where sp.league_id = p_league_id
      and r.season_id = p_season_id
      and r.sprint_race_at is not null
      and r.sprint_race_at < p_cutoff
    group by sp.user_id
  )
  select m.user_id,
         m.username,
         (coalesce(ms.total, 0) + coalesce(ss.total, 0))::bigint as total_score,
         (coalesce(ms.raced, 0) + coalesce(ss.raced, 0))::bigint as raced_count,
         row_number() over (
           order by (coalesce(ms.total, 0) + coalesce(ss.total, 0)) desc,
                    lower(m.username) asc
         ) as rnk
  from members m
  left join main_scores ms on ms.user_id = m.user_id
  left join sprint_scores ss on ss.user_id = m.user_id;
$$;

grant execute on function public.league_season_standings(uuid, smallint)
  to authenticated;

grant execute on function public.league_weekly_standings(uuid, uuid, boolean)
  to authenticated;

grant execute on function public.league_season_standings_before(uuid, smallint, timestamptz)
  to authenticated;
