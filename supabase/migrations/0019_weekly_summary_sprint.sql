-- 0019: league_weekly_summary'i sprint modunu da destekleyecek şekilde genişlet.
-- Eski 2 argümanlı imza korunur (varsayılan: ana yarış).

create or replace function public.league_weekly_summary(
  p_league_id uuid,
  p_race_id uuid,
  p_sprint boolean
) returns jsonb
language sql stable security definer set search_path = public as $$
  with main_predictions as (
    select p.id, p.user_id, p.score,
           p.winner_driver_id, p.p1_id, p.p2_id, p.p3_id,
           p.pole_driver_id, p.fastest_lap_driver_id,
           p.joker_option,
           pr.username
    from public.predictions p
    join public.league_memberships m
      on m.user_id = p.user_id
     and m.league_id = p_league_id
    join public.profiles pr on pr.id = p.user_id
    where p.league_id = p_league_id
      and p.race_id = p_race_id
      and not p_sprint
      and public.is_member_of(p_league_id)
  ),
  sprint_preds as (
    select sp.id, sp.user_id, sp.score,
           sp.winner_driver_id, sp.p1_id, sp.p2_id, sp.p3_id,
           sp.pole_driver_id,
           pr.username
    from public.sprint_predictions sp
    join public.league_memberships m
      on m.user_id = sp.user_id
     and m.league_id = p_league_id
    join public.profiles pr on pr.id = sp.user_id
    where sp.league_id = p_league_id
      and sp.race_id = p_race_id
      and p_sprint
      and public.is_member_of(p_league_id)
  ),
  member_predictions as (
    select id, user_id, score,
           winner_driver_id, p1_id, p2_id, p3_id,
           pole_driver_id, fastest_lap_driver_id,
           joker_option, username
    from main_predictions
    union all
    select id, user_id, score,
           winner_driver_id, p1_id, p2_id, p3_id,
           pole_driver_id, null::uuid as fastest_lap_driver_id,
           null::text as joker_option, username
    from sprint_preds
  ),
  standings as (
    select user_id, username, coalesce(score, 0) as score,
           rank() over (
             order by score desc nulls last,
                      lower(username) asc
           ) as rank
    from member_predictions
    where score is not null
  ),
  best_prediction as (
    select user_id, username, score
    from standings
    order by score desc, username
    limit 1
  ),
  joker_hits as (
    select count(*)::int as count
    from member_predictions p
    join public.race_results rr on rr.race_id = p_race_id
    where not p_sprint
      and p.joker_option is not null
      and rr.joker_correct is not null
      and p.joker_option = rr.joker_correct
  ),
  picks as (
    select winner_driver_id as driver_id from member_predictions where winner_driver_id is not null
    union all select p1_id from member_predictions where p1_id is not null
    union all select p2_id from member_predictions where p2_id is not null
    union all select p3_id from member_predictions where p3_id is not null
    union all select pole_driver_id from member_predictions where pole_driver_id is not null
    union all select fastest_lap_driver_id from member_predictions where fastest_lap_driver_id is not null
  ),
  most_picked as (
    select d.id, d.code, d.full_name, t.color, count(*)::int as pick_count
    from picks
    join public.drivers d on d.id = picks.driver_id
    left join public.teams t on t.id = d.team_id
    group by d.id, d.code, d.full_name, t.color
    order by count(*) desc, d.code
    limit 1
  ),
  top_rows as (
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

grant execute on function public.league_weekly_summary(uuid, uuid, boolean)
  to authenticated;
