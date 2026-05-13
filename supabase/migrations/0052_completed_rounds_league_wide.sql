-- 0052: `completed_rounds` artık kullanıcının kaç haftada tahmin yaptığını
-- değil, sezonun şu ana kadar bitmiş yarış sayısını göstersin.
-- Hero metni "X/Y hafta tamamlandı" tüm üyeler için aynı genel ilerlemeyi
-- yansıtır; kullanıcının tahmin sayısı zaten `prediction_count` alanında.

create or replace function public.league_user_overview_stats(
  p_league_id uuid,
  p_user_id uuid default null
) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_target uuid := coalesce(p_user_id, auth.uid());
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not public.is_member_of(p_league_id) then
    raise exception 'Only league members can view league stats' using errcode = '42501';
  end if;
  if not public.current_user_is_premium() then
    raise exception 'PREMIUM_REQUIRED' using errcode = '42501';
  end if;
  if v_target <> auth.uid() then
    raise exception 'Detailed league stats are private' using errcode = '42501';
  end if;

  with all_scores as (
    select r.id as race_id, r.name as race_name, r.round, p.user_id, p.score
    from public.predictions p
    join public.races r on r.id = p.race_id
    where p.league_id = p_league_id
      and p.score is not null
    union all
    select r.id as race_id, r.name as race_name, r.round, sp.user_id, sp.score
    from public.sprint_predictions sp
    join public.races r on r.id = sp.race_id
    where sp.league_id = p_league_id
      and sp.score is not null
  ),
  league_weekend_scores as (
    select race_id, race_name, round, user_id, sum(score)::int as weekend_score
    from all_scores
    group by race_id, race_name, round, user_id
  ),
  league_weekend_stats as (
    select race_id,
           coalesce(round(avg(weekend_score)::numeric, 1), 0) as league_avg,
           count(*)::int as scored_members
    from league_weekend_scores group by race_id
  ),
  league_weekend_ranks as (
    select race_id, user_id,
           rank() over (partition by race_id order by weekend_score desc) as weekend_rank
    from league_weekend_scores
  ),
  rows as (
    select s.race_id, s.race_name, s.round, s.weekend_score as score,
           coalesce(w.league_avg, 0) as league_avg,
           coalesce(r.weekend_rank, 0) as position
    from league_weekend_scores s
    left join league_weekend_stats w on w.race_id = s.race_id
    left join league_weekend_ranks r on r.race_id = s.race_id and r.user_id = s.user_id
    where s.user_id = v_target
  ),
  trend_rows as (
    select r.id as race_id, r.name as race_name, r.round,
           coalesce(u.score, 0) as score,
           coalesce(s.league_avg, 0) as league_avg,
           coalesce(u.position, 0) as position
    from public.races r
    left join league_weekend_stats s on s.race_id = r.id
    left join rows u on u.race_id = r.id
    where r.season_id = (select season_id from public.leagues where id = p_league_id)
      and r.race_at + interval '3 hours' < now()
      and r.status <> 'cancelled'
  ),
  standings as (
    select * from public.league_season_standings(
      p_league_id,
      (select season_id from public.leagues where id = p_league_id)
    )
  ),
  league_scores as (select total_score from standings),
  league_meta as (
    select l.season_id,
           (select count(*)::int from public.league_memberships m where m.league_id = p_league_id) as member_count,
           (select count(*)::int from public.races r where r.season_id = l.season_id) as total_rounds,
           -- sezonun şu ana kadar bitmiş (cancelled olmayan) yarış sayısı
           (select count(*)::int from public.races r
            where r.season_id = l.season_id
              and r.race_at + interval '3 hours' < now()
              and r.status <> 'cancelled') as completed_season_rounds
    from public.leagues l
    where l.id = p_league_id
  ),
  user_totals as (
    select coalesce(sum(score), 0)::int as total_points,
           coalesce(round(avg(score)::numeric, 1), 0) as average_points
    from rows
  ),
  picks as (select count(*)::int as prediction_count from rows),
  best as (
    select race_id, race_name, round, score, league_avg, position from rows
    order by score desc, round asc limit 1
  ),
  worst as (
    select race_id, race_name, round, score, league_avg, position from rows
    order by score asc, round asc limit 1
  ),
  trend as (
    select coalesce(jsonb_agg(jsonb_build_object(
      'race_id', race_id, 'race_name', race_name, 'round', round,
      'score', score, 'league_avg', league_avg, 'position', position
    ) order by round), '[]'::jsonb) as items
    from trend_rows
  )
  select jsonb_build_object(
    'total_points', (select total_points from user_totals),
    'current_rank', coalesce((select rnk from standings where user_id = v_target), 0),
    'average_points', (select average_points from user_totals),
    'best_weekend', coalesce((select to_jsonb(best) from best), '{}'::jsonb),
    'worst_weekend', coalesce((select to_jsonb(worst) from worst), '{}'::jsonb),
    'prediction_count', coalesce((select prediction_count from picks), 0),
    'completed_rounds', coalesce((select completed_season_rounds from league_meta), 0),
    'total_rounds', coalesce((select total_rounds from league_meta), 0),
    'member_count', coalesce((select member_count from league_meta), 0),
    'leader_score', coalesce((select max(total_score)::int from standings), 0),
    'lowest_score', coalesce((select min(total_score)::int from standings), 0),
    'leader_gap', greatest(coalesce((select max(total_score)::int from standings), 0) - (select total_points from user_totals), 0),
    'league_average_points', coalesce(round(avg(league_scores.total_score)::numeric, 1), 0),
    'trend', (select items from trend)
  ) into v_result
  from league_scores;

  return coalesce(v_result, jsonb_build_object(
    'total_points', 0, 'current_rank', 0, 'average_points', 0,
    'best_weekend', '{}'::jsonb, 'worst_weekend', '{}'::jsonb,
    'prediction_count', 0, 'completed_rounds', 0, 'total_rounds', 0,
    'member_count', 0, 'leader_score', 0, 'lowest_score', 0,
    'leader_gap', 0, 'league_average_points', 0, 'trend', '[]'::jsonb
  ));
end;
$$;
