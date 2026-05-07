-- 0032: Weekly share cards need the current user's score/rank and
-- per-question prediction hits for main and sprint summaries.

create or replace function public.league_weekly_summary(
  p_league_id uuid,
  p_race_id uuid,
  p_sprint boolean
) returns jsonb
language sql stable security definer set search_path = public as $$
  with main_predictions as (
    select p.id, p.user_id, p.score,
           p.winner_driver_id, p.p1_id, p.p2_id, p.p3_id,
           p.top_team_id, p.pole_driver_id, p.fastest_lap_driver_id,
           p.dnf_count, p.safety_car, p.joker_option,
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
           sp.top_team_id, sp.pole_driver_id,
           sp.dnf_count, sp.safety_car,
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
           top_team_id, pole_driver_id, fastest_lap_driver_id,
           dnf_count, safety_car, joker_option, username
    from main_predictions
    union all
    select id, user_id, score,
           winner_driver_id, p1_id, p2_id, p3_id,
           top_team_id, pole_driver_id, null::uuid as fastest_lap_driver_id,
           dnf_count, safety_car, null::text as joker_option, username
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
    select user_id, username, score, rank
    from standings
    order by score desc, lower(username)
    limit 1
  ),
  my_standing as (
    select user_id, username, score, rank
    from standings
    where user_id = auth.uid()
    limit 1
  ),
  my_main_prediction as (
    select *
    from main_predictions
    where user_id = auth.uid()
    limit 1
  ),
  my_sprint_prediction as (
    select *
    from sprint_preds
    where user_id = auth.uid()
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
  main_prediction_items as (
    select jsonb_build_array(
      jsonb_build_object(
        'label', 'YARIŞ GALİBİ',
        'value', coalesce((select code from public.drivers where id = p.winner_driver_id), '-'),
        'status', case when p.winner_driver_id is not null and p.winner_driver_id = rr.p1 then 'correct' else 'wrong' end,
        'hit', p.winner_driver_id is not null and p.winner_driver_id = rr.p1,
        'points', case when p.winner_driver_id is not null and p.winner_driver_id = rr.p1 then 10 else 0 end,
        'max_points', 10
      ),
      jsonb_build_object(
        'label', 'PODYUM P1',
        'value', coalesce((select code from public.drivers where id = p.p1_id), '-'),
        'status', case
          when p.p1_id is not null and p.p1_id = rr.p1 then 'correct'
          when p.p1_id is not null and p.p1_id in (rr.p1, rr.p2, rr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p1_id is not null and p.p1_id in (rr.p1, rr.p2, rr.p3),
        'points', case
          when p.p1_id is not null and p.p1_id = rr.p1 then 7
          when p.p1_id is not null and p.p1_id in (rr.p1, rr.p2, rr.p3) then 5
          else 0
        end,
        'max_points', 7
      ),
      jsonb_build_object(
        'label', 'PODYUM P2',
        'value', coalesce((select code from public.drivers where id = p.p2_id), '-'),
        'status', case
          when p.p2_id is not null and p.p2_id = rr.p2 then 'correct'
          when p.p2_id is not null and p.p2_id in (rr.p1, rr.p2, rr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p2_id is not null and p.p2_id in (rr.p1, rr.p2, rr.p3),
        'points', case
          when p.p2_id is not null and p.p2_id = rr.p2 then 7
          when p.p2_id is not null and p.p2_id in (rr.p1, rr.p2, rr.p3) then 5
          else 0
        end,
        'max_points', 7
      ),
      jsonb_build_object(
        'label', 'PODYUM P3',
        'value', coalesce((select code from public.drivers where id = p.p3_id), '-'),
        'status', case
          when p.p3_id is not null and p.p3_id = rr.p3 then 'correct'
          when p.p3_id is not null and p.p3_id in (rr.p1, rr.p2, rr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p3_id is not null and p.p3_id in (rr.p1, rr.p2, rr.p3),
        'points', case
          when p.p3_id is not null and p.p3_id = rr.p3 then 7
          when p.p3_id is not null and p.p3_id in (rr.p1, rr.p2, rr.p3) then 5
          else 0
        end,
        'max_points', 7
      ),
      jsonb_build_object(
        'label', 'PODYUM BONUS',
        'value', case
          when p.p1_id = rr.p1 and p.p2_id = rr.p2 and p.p3_id = rr.p3 then 'TAM'
          else '-'
        end,
        'status', case
          when p.p1_id = rr.p1 and p.p2_id = rr.p2 and p.p3_id = rr.p3 then 'correct'
          else 'wrong'
        end,
        'hit', p.p1_id = rr.p1 and p.p2_id = rr.p2 and p.p3_id = rr.p3,
        'points', case
          when p.p1_id = rr.p1 and p.p2_id = rr.p2 and p.p3_id = rr.p3 then 3
          else 0
        end,
        'max_points', 3
      ),
      jsonb_build_object(
        'label', 'TOP TEAM',
        'value', coalesce((select code from public.teams where id = p.top_team_id), '-'),
        'status', case when p.top_team_id is not null and p.top_team_id = rr.top_team_id then 'correct' else 'wrong' end,
        'hit', p.top_team_id is not null and p.top_team_id = rr.top_team_id,
        'points', case when p.top_team_id is not null and p.top_team_id = rr.top_team_id then 10 else 0 end,
        'max_points', 10
      ),
      jsonb_build_object(
        'label', 'POLE',
        'value', coalesce((select code from public.drivers where id = p.pole_driver_id), '-'),
        'status', case when p.pole_driver_id is not null and p.pole_driver_id = rr.pole then 'correct' else 'wrong' end,
        'hit', p.pole_driver_id is not null and p.pole_driver_id = rr.pole,
        'points', case when p.pole_driver_id is not null and p.pole_driver_id = rr.pole then 8 else 0 end,
        'max_points', 8
      ),
      jsonb_build_object(
        'label', 'DNF',
        'value', coalesce(p.dnf_count::text, '-'),
        'status', case
          when p.dnf_count is not null and p.dnf_count = rr.dnf_count then 'correct'
          when p.dnf_count is not null and abs(p.dnf_count - rr.dnf_count) = 1 then 'partial'
          else 'wrong'
        end,
        'hit', p.dnf_count is not null and abs(p.dnf_count - rr.dnf_count) <= 1,
        'points', case
          when p.dnf_count is not null and p.dnf_count = rr.dnf_count then 6
          when p.dnf_count is not null and abs(p.dnf_count - rr.dnf_count) = 1 then 3
          else 0
        end,
        'max_points', 6
      ),
      jsonb_build_object(
        'label', 'GÜVENLİK ARACI',
        'value', case
          when p.safety_car is null then '-'
          when p.safety_car then 'VAR'
          else 'YOK'
        end,
        'status', case when p.safety_car is not null and p.safety_car = rr.safety_car then 'correct' else 'wrong' end,
        'hit', p.safety_car is not null and p.safety_car = rr.safety_car,
        'points', case when p.safety_car is not null and p.safety_car = rr.safety_car then 3 else 0 end,
        'max_points', 3
      ),
      jsonb_build_object(
        'label', 'JOKER',
        'value', coalesce(upper(p.joker_option), '-'),
        'status', case when p.joker_option is not null
           and rr.joker_correct is not null
           and p.joker_option = rr.joker_correct then 'correct' else 'wrong' end,
        'hit', p.joker_option is not null
           and rr.joker_correct is not null
           and p.joker_option = rr.joker_correct,
        'points', case when p.joker_option is not null
           and rr.joker_correct is not null
           and p.joker_option = rr.joker_correct
          then coalesce((select points from public.joker_questions where race_id = p_race_id limit 1), 12)
          else 0
        end,
        'max_points', coalesce((select points from public.joker_questions where race_id = p_race_id limit 1), 12)
      )
    ) as rows
    from my_main_prediction p
    join public.race_results rr on rr.race_id = p_race_id
    where not p_sprint
  ),
  sprint_prediction_items as (
    select jsonb_build_array(
      jsonb_build_object(
        'label', 'SPRINT GALİBİ',
        'value', coalesce((select code from public.drivers where id = p.winner_driver_id), '-'),
        'status', case when p.winner_driver_id is not null and p.winner_driver_id = sr.p1 then 'correct' else 'wrong' end,
        'hit', p.winner_driver_id is not null and p.winner_driver_id = sr.p1,
        'points', case when p.winner_driver_id is not null and p.winner_driver_id = sr.p1 then 8 else 0 end,
        'max_points', 8
      ),
      jsonb_build_object(
        'label', 'PODYUM P1',
        'value', coalesce((select code from public.drivers where id = p.p1_id), '-'),
        'status', case
          when p.p1_id is not null and p.p1_id = sr.p1 then 'correct'
          when p.p1_id is not null and p.p1_id in (sr.p1, sr.p2, sr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p1_id is not null and p.p1_id in (sr.p1, sr.p2, sr.p3),
        'points', case
          when p.p1_id is not null and p.p1_id = sr.p1 then 5
          when p.p1_id is not null and p.p1_id in (sr.p1, sr.p2, sr.p3) then 4
          else 0
        end,
        'max_points', 5
      ),
      jsonb_build_object(
        'label', 'PODYUM P2',
        'value', coalesce((select code from public.drivers where id = p.p2_id), '-'),
        'status', case
          when p.p2_id is not null and p.p2_id = sr.p2 then 'correct'
          when p.p2_id is not null and p.p2_id in (sr.p1, sr.p2, sr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p2_id is not null and p.p2_id in (sr.p1, sr.p2, sr.p3),
        'points', case
          when p.p2_id is not null and p.p2_id = sr.p2 then 5
          when p.p2_id is not null and p.p2_id in (sr.p1, sr.p2, sr.p3) then 4
          else 0
        end,
        'max_points', 5
      ),
      jsonb_build_object(
        'label', 'PODYUM P3',
        'value', coalesce((select code from public.drivers where id = p.p3_id), '-'),
        'status', case
          when p.p3_id is not null and p.p3_id = sr.p3 then 'correct'
          when p.p3_id is not null and p.p3_id in (sr.p1, sr.p2, sr.p3) then 'partial'
          else 'wrong'
        end,
        'hit', p.p3_id is not null and p.p3_id in (sr.p1, sr.p2, sr.p3),
        'points', case
          when p.p3_id is not null and p.p3_id = sr.p3 then 5
          when p.p3_id is not null and p.p3_id in (sr.p1, sr.p2, sr.p3) then 4
          else 0
        end,
        'max_points', 5
      ),
      jsonb_build_object(
        'label', 'PODYUM BONUS',
        'value', case
          when p.p1_id = sr.p1 and p.p2_id = sr.p2 and p.p3_id = sr.p3 then 'TAM'
          else '-'
        end,
        'status', case
          when p.p1_id = sr.p1 and p.p2_id = sr.p2 and p.p3_id = sr.p3 then 'correct'
          else 'wrong'
        end,
        'hit', p.p1_id = sr.p1 and p.p2_id = sr.p2 and p.p3_id = sr.p3,
        'points', case
          when p.p1_id = sr.p1 and p.p2_id = sr.p2 and p.p3_id = sr.p3 then 2
          else 0
        end,
        'max_points', 2
      ),
      jsonb_build_object(
        'label', 'TOP TEAM',
        'value', coalesce((select code from public.teams where id = p.top_team_id), '-'),
        'status', case when p.top_team_id is not null and p.top_team_id = sr.top_team_id then 'correct' else 'wrong' end,
        'hit', p.top_team_id is not null and p.top_team_id = sr.top_team_id,
        'points', case when p.top_team_id is not null and p.top_team_id = sr.top_team_id then 8 else 0 end,
        'max_points', 8
      ),
      jsonb_build_object(
        'label', 'SPRINT POLE',
        'value', coalesce((select code from public.drivers where id = p.pole_driver_id), '-'),
        'status', case when p.pole_driver_id is not null and p.pole_driver_id = sr.pole then 'correct' else 'wrong' end,
        'hit', p.pole_driver_id is not null and p.pole_driver_id = sr.pole,
        'points', case when p.pole_driver_id is not null and p.pole_driver_id = sr.pole then 6 else 0 end,
        'max_points', 6
      ),
      jsonb_build_object(
        'label', 'DNF',
        'value', coalesce(p.dnf_count::text, '-'),
        'status', case
          when p.dnf_count is not null and p.dnf_count = sr.dnf_count then 'correct'
          when p.dnf_count is not null and abs(p.dnf_count - sr.dnf_count) = 1 then 'partial'
          else 'wrong'
        end,
        'hit', p.dnf_count is not null and abs(p.dnf_count - sr.dnf_count) <= 1,
        'points', case
          when p.dnf_count is not null and p.dnf_count = sr.dnf_count then 4
          when p.dnf_count is not null and abs(p.dnf_count - sr.dnf_count) = 1 then 2
          else 0
        end,
        'max_points', 4
      ),
      jsonb_build_object(
        'label', 'GÜVENLİK ARACI',
        'value', case
          when p.safety_car is null then '-'
          when p.safety_car then 'VAR'
          else 'YOK'
        end,
        'status', case when p.safety_car is not null and p.safety_car = sr.safety_car then 'correct' else 'wrong' end,
        'hit', p.safety_car is not null and p.safety_car = sr.safety_car,
        'points', case when p.safety_car is not null and p.safety_car = sr.safety_car then 2 else 0 end,
        'max_points', 2
      )
    ) as rows
    from my_sprint_prediction p
    join public.sprint_results sr on sr.race_id = p_race_id
    where p_sprint
  ),
  prediction_items as (
    select coalesce(
      (select rows from main_prediction_items),
      (select rows from sprint_prediction_items),
      '[]'::jsonb
    ) as rows
  ),
  main_driver_points as (
    select p.winner_driver_id as driver_id,
           case when p.winner_driver_id = rr.p1 then 10 else 0 end as points
    from main_predictions p
    join public.race_results rr on rr.race_id = p_race_id
    where p.winner_driver_id is not null
    union all
    select pick.driver_id,
           case when pick.driver_id in (rr.p1, rr.p2, rr.p3) then 5 else 0 end
           + case when pick.driver_id = pick.actual_id then 2 else 0 end as points
    from main_predictions p
    join public.race_results rr on rr.race_id = p_race_id
    cross join lateral (values
      (p.p1_id, rr.p1),
      (p.p2_id, rr.p2),
      (p.p3_id, rr.p3)
    ) as pick(driver_id, actual_id)
    where pick.driver_id is not null
    union all
    select p.pole_driver_id as driver_id,
           case when p.pole_driver_id = rr.pole then 8 else 0 end as points
    from main_predictions p
    join public.race_results rr on rr.race_id = p_race_id
    where p.pole_driver_id is not null
  ),
  sprint_driver_points as (
    select p.winner_driver_id as driver_id,
           case when p.winner_driver_id = sr.p1 then 8 else 0 end as points
    from sprint_preds p
    join public.sprint_results sr on sr.race_id = p_race_id
    where p.winner_driver_id is not null
    union all
    select pick.driver_id,
           case when pick.driver_id in (sr.p1, sr.p2, sr.p3) then 4 else 0 end
           + case when pick.driver_id = pick.actual_id then 1 else 0 end
           + case
               when p.p1_id = sr.p1 and p.p2_id = sr.p2 and p.p3_id = sr.p3
               then 2
               else 0
             end as points
    from sprint_preds p
    join public.sprint_results sr on sr.race_id = p_race_id
    cross join lateral (values
      (p.p1_id, sr.p1),
      (p.p2_id, sr.p2),
      (p.p3_id, sr.p3)
    ) as pick(driver_id, actual_id)
    where pick.driver_id is not null
    union all
    select p.pole_driver_id as driver_id,
           case when p.pole_driver_id = sr.pole then 6 else 0 end as points
    from sprint_preds p
    join public.sprint_results sr on sr.race_id = p_race_id
    where p.pole_driver_id is not null
  ),
  driver_points as (
    select driver_id, points
    from main_driver_points
    where not p_sprint
    union all
    select driver_id, points
    from sprint_driver_points
    where p_sprint
  ),
  best_driver as (
    select d.id, d.code, d.full_name, t.color,
           count(*)::int as pick_count,
           sum(dp.points)::int as points
    from driver_points dp
    join public.drivers d on d.id = dp.driver_id
    left join public.teams t on t.id = d.team_id
    group by d.id, d.code, d.full_name, t.color
    having sum(dp.points) > 0
    order by sum(dp.points) desc, count(*) desc, d.code
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
    'my_standing', coalesce((select to_jsonb(my_standing) from my_standing), '{}'::jsonb),
    'joker_hit_count', coalesce((select count from joker_hits), 0),
    'most_picked_driver', coalesce((select to_jsonb(best_driver) from best_driver), '{}'::jsonb),
    'top_standings', (select rows from top_rows),
    'prediction_count', (select count(*) from member_predictions),
    'prediction_items', (select rows from prediction_items)
  );
$$;

grant execute on function public.league_weekly_summary(uuid, uuid, boolean)
  to authenticated;
