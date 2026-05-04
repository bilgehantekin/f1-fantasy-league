-- GridCall — detaylı profil istatistik RPC'leri

-- Kategori bazlı doğruluk (winner / podium_exact / pole / fastest_lap / dnf_exact / joker)
create or replace function public.user_category_accuracy(p_user_id uuid, p_season_id smallint)
returns table(category text, correct int, total int)
language sql stable security definer set search_path = public as $$
  with scored as (
    select p.*, rr.p1 as r_p1, rr.p2 as r_p2, rr.p3 as r_p3,
           rr.pole as r_pole, rr.fastest_lap as r_fl,
           rr.dnf_count as r_dnf, rr.joker_correct as r_joker
    from public.predictions p
    join public.races r on r.id = p.race_id
    join public.race_results rr on rr.race_id = p.race_id
    where p.user_id = p_user_id and r.season_id = p_season_id
  )
  select 'winner'::text,
         sum(case when winner_driver_id = r_p1 then 1 else 0 end)::int,
         count(*)::int
  from scored
  union all
  select 'podium_exact',
         sum(case when p1_id=r_p1 and p2_id=r_p2 and p3_id=r_p3 then 1 else 0 end)::int,
         count(*)::int
  from scored
  union all
  select 'pole',
         sum(case when pole_driver_id = r_pole then 1 else 0 end)::int,
         count(*)::int
  from scored
  union all
  select 'fastest_lap',
         sum(case when fastest_lap_driver_id = r_fl then 1 else 0 end)::int,
         count(*)::int
  from scored
  union all
  select 'dnf_exact',
         sum(case when dnf_count = r_dnf then 1 else 0 end)::int,
         count(*)::int
  from scored
  union all
  select 'joker',
         sum(case when joker_option = r_joker then 1 else 0 end)::int,
         count(case when joker_option is not null and r_joker is not null then 1 end)::int
  from scored;
$$;

-- Sezon trendi: round başına puan
create or replace function public.user_season_trend(p_user_id uuid, p_season_id smallint)
returns table(round smallint, race_name text, score int)
language sql stable security definer set search_path = public as $$
  select r.round, r.name, p.score
  from public.predictions p
  join public.races r on r.id = p.race_id
  where p.user_id = p_user_id and r.season_id = p_season_id and p.score is not null
  order by r.round;
$$;

-- Sürücü bazlı isabet: 6 slottaki tahminler birleştirilir (winner, p1-p3, pole, fl)
create or replace function public.user_driver_accuracy(p_user_id uuid, p_season_id smallint)
returns table(code text, full_name text, color text, predicted int, correct int)
language sql stable security definer set search_path = public as $$
  with base as (
    select p.user_id, p.race_id, p.winner_driver_id, p.p1_id, p.p2_id, p.p3_id,
           p.pole_driver_id, p.fastest_lap_driver_id,
           rr.p1, rr.p2, rr.p3, rr.pole, rr.fastest_lap
    from public.predictions p
    join public.races r on r.id = p.race_id
    join public.race_results rr on rr.race_id = p.race_id
    where p.user_id = p_user_id and r.season_id = p_season_id
  ), picks as (
    select winner_driver_id as driver_id,
           (winner_driver_id = p1)::int as hit from base where winner_driver_id is not null
    union all select p1_id, (p1_id = p1)::int from base where p1_id is not null
    union all select p2_id, (p2_id = p2)::int from base where p2_id is not null
    union all select p3_id, (p3_id = p3)::int from base where p3_id is not null
    union all select pole_driver_id, (pole_driver_id = pole)::int
      from base where pole_driver_id is not null
    union all select fastest_lap_driver_id, (fastest_lap_driver_id = fastest_lap)::int
      from base where fastest_lap_driver_id is not null
  )
  select d.code, d.full_name, t.color,
         count(*)::int,
         sum(picks.hit)::int
  from picks
  join public.drivers d on d.id = picks.driver_id
  left join public.teams t on t.id = d.team_id
  group by d.id, d.code, d.full_name, t.color
  order by count(*) desc, sum(picks.hit) desc
  limit 10;
$$;

grant execute on function public.user_category_accuracy(uuid, smallint) to authenticated, service_role;
grant execute on function public.user_season_trend(uuid, smallint) to authenticated, service_role;
grant execute on function public.user_driver_accuracy(uuid, smallint) to authenticated, service_role;
