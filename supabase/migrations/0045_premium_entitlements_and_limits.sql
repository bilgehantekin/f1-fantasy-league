-- 0045: Production premium entitlements, league limits, favorites, and stats.
-- No development premium toggles are introduced here.

create table if not exists public.user_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entitlement text not null check (entitlement in ('premium')),
  source text not null check (source in ('revenuecat', 'app_store', 'play_store')),
  product_id text,
  original_transaction_id text,
  store_subscription_id text,
  store_identity text generated always as (
    coalesce(original_transaction_id, store_subscription_id, product_id, '')
  ) stored,
  status text not null check (status in ('active', 'trialing', 'grace_period', 'expired', 'canceled')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_entitlements_user_idx
  on public.user_entitlements(user_id, entitlement, status, current_period_end);

create unique index if not exists user_entitlements_store_identity_key
  on public.user_entitlements(
    user_id,
    entitlement,
    source,
    store_identity
  );

drop trigger if exists user_entitlements_updated_at on public.user_entitlements;
create trigger user_entitlements_updated_at
  before update on public.user_entitlements
  for each row execute function public.set_updated_at();

alter table public.user_entitlements enable row level security;

drop policy if exists "user_entitlements_read_self" on public.user_entitlements;
create policy "user_entitlements_read_self"
on public.user_entitlements for select
using (user_id = auth.uid());

grant select on public.user_entitlements to authenticated;
grant all on public.user_entitlements to service_role;

create or replace function public.current_user_is_premium()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.user_entitlements e
    where e.user_id = auth.uid()
      and e.entitlement = 'premium'
      and e.status in ('active', 'trialing', 'grace_period')
      and e.current_period_end is not null
      and e.current_period_end > now()
  );
$$;

grant execute on function public.current_user_is_premium() to authenticated;

create or replace function public.premium_league_limits_enabled()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    nullif(current_setting('app.enable_premium_league_limits', true), '')::boolean,
    false
  );
$$;

grant execute on function public.premium_league_limits_enabled() to authenticated;

create or replace function public.user_is_premium(p_user_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.user_entitlements e
    where e.user_id = p_user_id
      and e.entitlement = 'premium'
      and e.status in ('active', 'trialing', 'grace_period')
      and e.current_period_end is not null
      and e.current_period_end > now()
  );
$$;

grant execute on function public.user_is_premium(uuid) to authenticated;

create or replace function public.sync_tier_from_entitlements()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set tier = case
    when public.user_is_premium(case when TG_OP = 'DELETE' then old.user_id else new.user_id end) then 'premium'::public.user_tier
    else 'free'::public.user_tier
  end
  where id = case when TG_OP = 'DELETE' then old.user_id else new.user_id end;

  if TG_OP = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists user_entitlements_sync_tier_insert on public.user_entitlements;
create trigger user_entitlements_sync_tier_insert
  after insert or update or delete on public.user_entitlements
  for each row execute function public.sync_tier_from_entitlements();

create or replace function public.active_league_limit_for(p_user_id uuid)
returns int
language sql stable security definer set search_path = public as $$
  select case
    when not public.premium_league_limits_enabled() then 2147483647
    when public.user_is_premium(p_user_id) then 10
    else 2
  end;
$$;

create or replace function public.active_league_count_for(p_user_id uuid, p_season_id smallint)
returns int
language sql stable security definer set search_path = public as $$
  select count(*)::int
  from public.league_memberships m
  join public.leagues l on l.id = m.league_id
  where m.user_id = p_user_id
    and l.season_id = p_season_id;
$$;

create or replace function public.can_add_active_league_membership(
  p_user_id uuid,
  p_league_id uuid
) returns boolean
language sql stable security definer set search_path = public as $$
  with target as (
    select season_id from public.leagues where id = p_league_id
  )
  select exists (select 1 from target)
     and public.active_league_count_for(p_user_id, (select season_id from target))
         < public.active_league_limit_for(p_user_id);
$$;

create or replace function public.assert_can_add_active_league_membership(
  p_user_id uuid,
  p_league_id uuid
) returns void
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.can_add_active_league_membership(p_user_id, p_league_id) then
    raise exception 'FREE_LEAGUE_LIMIT_REACHED'
      using errcode = 'P0001',
            detail = 'Free accounts can join up to 2 active leagues. Upgrade to Premium to join up to 10.';
  end if;
end;
$$;

grant execute on function public.active_league_limit_for(uuid) to authenticated;
grant execute on function public.active_league_count_for(uuid, smallint) to authenticated;
grant execute on function public.can_add_active_league_membership(uuid, uuid) to authenticated;

drop policy if exists "leagues_insert_self" on public.leagues;
create policy "leagues_insert_self" on public.leagues for insert with check (
  auth.uid() = owner_id
  and public.active_league_count_for(auth.uid(), season_id) < public.active_league_limit_for(auth.uid())
);

drop policy if exists "memberships_insert_self" on public.league_memberships;
create policy "memberships_insert_self" on public.league_memberships for insert with check (
  user_id = auth.uid()
  and public.can_add_active_league_membership(auth.uid(), league_id)
);

create or replace function public.join_league_by_code(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  select id into v_league_id from public.leagues where invite_code = upper(p_code);
  if v_league_id is null then
    raise exception 'Invalid invite code' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from public.league_memberships
    where league_id = v_league_id and user_id = auth.uid()
  ) then
    return v_league_id;
  end if;
  perform public.assert_can_add_active_league_membership(auth.uid(), v_league_id);
  insert into public.league_memberships (league_id, user_id, role)
  values (v_league_id, auth.uid(), 'member');
  return v_league_id;
end$$;

create or replace function public.create_league(
  p_name text,
  p_season_id smallint,
  p_type public.league_type default 'private'
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
  v_code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if public.active_league_count_for(auth.uid(), p_season_id) >= public.active_league_limit_for(auth.uid()) then
    raise exception 'FREE_LEAGUE_LIMIT_REACHED'
      using errcode = 'P0001',
            detail = 'Free accounts can join up to 2 active leagues. Upgrade to Premium to join up to 10.';
  end if;
  v_code := public.generate_invite_code();
  insert into public.leagues (name, type, owner_id, invite_code, season_id)
  values (p_name, p_type, auth.uid(), v_code, p_season_id)
  returning id into v_league_id;
  return v_league_id;
end$$;

grant execute on function public.create_league(text, smallint, public.league_type) to authenticated;
grant execute on function public.join_league_by_code(text) to authenticated;

create table if not exists public.league_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  league_id uuid not null references public.leagues(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, league_id)
);

alter table public.league_favorites enable row level security;

drop policy if exists "league_favorites_read_self" on public.league_favorites;
create policy "league_favorites_read_self" on public.league_favorites
for select using (user_id = auth.uid());

drop policy if exists "league_favorites_delete_self" on public.league_favorites;
create policy "league_favorites_delete_self" on public.league_favorites
for delete using (user_id = auth.uid());

grant select, delete on public.league_favorites to authenticated;
grant all on public.league_favorites to service_role;

create or replace function public.set_league_favorite(
  p_league_id uuid,
  p_favorite boolean
) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not public.is_member_of(p_league_id) then
    raise exception 'Only league members can favorite this league' using errcode = '42501';
  end if;
  if not public.current_user_is_premium() then
    raise exception 'PREMIUM_REQUIRED' using errcode = '42501';
  end if;

  if p_favorite then
    insert into public.league_favorites(user_id, league_id)
    values (auth.uid(), p_league_id)
    on conflict (user_id, league_id) do nothing;
    return true;
  end if;

  delete from public.league_favorites
  where user_id = auth.uid() and league_id = p_league_id;
  return false;
end;
$$;

create or replace function public.toggle_league_favorite(p_league_id uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_exists boolean;
begin
  select exists(
    select 1 from public.league_favorites
    where user_id = auth.uid() and league_id = p_league_id
  ) into v_exists;
  return public.set_league_favorite(p_league_id, not v_exists);
end;
$$;

grant execute on function public.set_league_favorite(uuid, boolean) to authenticated;
grant execute on function public.toggle_league_favorite(uuid) to authenticated;

drop function if exists public.league_members(uuid);
create or replace function public.league_members(p_league_id uuid)
returns table(user_id uuid, username text, role text, joined_at timestamptz, is_premium boolean)
language sql stable security definer set search_path = public as $$
  select m.user_id,
         p.username,
         m.role,
         m.joined_at,
         public.user_is_premium(m.user_id) as is_premium
  from public.league_memberships m
  join public.profiles p on p.id = m.user_id
  where m.league_id = p_league_id
    and public.is_member_of(p_league_id)
  order by m.joined_at;
$$;

drop function if exists public.league_season_standings(uuid, smallint);
create or replace function public.league_season_standings(
  p_league_id uuid,
  p_season_id smallint
) returns table(
  user_id uuid,
  username text,
  total_score bigint,
  raced_count bigint,
  rnk bigint,
  is_premium boolean
)
language sql stable security definer set search_path = public as $$
  with members as (
    select m.user_id, pr.username, public.user_is_premium(m.user_id) as is_premium
    from public.league_memberships m
    join public.profiles pr on pr.id = m.user_id
    where m.league_id = p_league_id
      and public.is_member_of(p_league_id)
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
         ) as rnk,
         m.is_premium
  from members m
  left join main_scores ms on ms.user_id = m.user_id
  left join sprint_scores ss on ss.user_id = m.user_id;
$$;

drop function if exists public.league_weekly_standings(uuid, uuid, boolean);
create or replace function public.league_weekly_standings(
  p_league_id uuid,
  p_race_id uuid,
  p_sprint boolean
) returns table(
  user_id uuid,
  username text,
  score int,
  rnk bigint,
  is_premium boolean
)
language sql stable security definer set search_path = public as $$
  with members as (
    select m.user_id, pr.username, public.user_is_premium(m.user_id) as is_premium
    from public.league_memberships m
    join public.profiles pr on pr.id = m.user_id
    where m.league_id = p_league_id
      and public.is_member_of(p_league_id)
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
         ) as rnk,
         m.is_premium
  from members m
  left join scored s on s.user_id = m.user_id;
$$;

grant execute on function public.league_members(uuid) to authenticated;
grant execute on function public.league_season_standings(uuid, smallint) to authenticated;
grant execute on function public.league_weekly_standings(uuid, uuid, boolean) to authenticated;

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
    select r.id as race_id,
           r.name as race_name,
           r.round,
           p.user_id,
           p.score
    from public.predictions p
    join public.races r on r.id = p.race_id
    where p.league_id = p_league_id
      and p.score is not null
    union all
    select r.id as race_id,
           r.name as race_name,
           r.round,
           sp.user_id,
           sp.score
    from public.sprint_predictions sp
    join public.races r on r.id = sp.race_id
    where sp.league_id = p_league_id
      and sp.score is not null
  ),
  league_weekend_scores as (
    select race_id,
           race_name,
           round,
           user_id,
           sum(score)::int as weekend_score
    from all_scores
    group by race_id, race_name, round, user_id
  ),
  league_weekend_stats as (
    select race_id,
           coalesce(round(avg(weekend_score)::numeric, 1), 0) as league_avg,
           count(*)::int as scored_members
    from league_weekend_scores
    group by race_id
  ),
  league_weekend_ranks as (
    select race_id,
           user_id,
           rank() over (partition by race_id order by weekend_score desc) as weekend_rank
    from league_weekend_scores
  ),
  rows as (
    select s.race_id,
           s.race_name,
           s.round,
           s.weekend_score as score,
           coalesce(w.league_avg, 0) as league_avg,
           coalesce(r.weekend_rank, 0) as position
    from league_weekend_scores s
    left join league_weekend_stats w on w.race_id = s.race_id
    left join league_weekend_ranks r on r.race_id = s.race_id and r.user_id = s.user_id
    where s.user_id = v_target
  ),
  standings as (
    select * from public.league_season_standings(
      p_league_id,
      (select season_id from public.leagues where id = p_league_id)
    )
  ),
  league_scores as (
    select total_score from standings
  ),
  league_meta as (
    select l.season_id,
           (select count(*)::int from public.league_memberships m where m.league_id = p_league_id) as member_count,
           (select count(*)::int from public.races r where r.season_id = l.season_id) as total_rounds
    from public.leagues l
    where l.id = p_league_id
  ),
  user_totals as (
    select
      coalesce(sum(score), 0)::int as total_points,
      coalesce(round(avg(score)::numeric, 1), 0) as average_points
    from rows
  ),
  picks as (
    select count(*)::int as prediction_count from rows
  ),
  best as (
    select race_id, race_name, round, score, league_avg, position from rows
    order by score desc, round asc
    limit 1
  ),
  worst as (
    select race_id, race_name, round, score, league_avg, position from rows
    order by score asc, round asc
    limit 1
  ),
  trend as (
    select coalesce(jsonb_agg(jsonb_build_object(
      'race_id', race_id,
      'race_name', race_name,
      'round', round,
      'score', score,
      'league_avg', league_avg,
      'position', position
    ) order by round), '[]'::jsonb) as items
    from rows
  )
  select jsonb_build_object(
    'total_points', (select total_points from user_totals),
    'current_rank', coalesce((select rnk from standings where user_id = v_target), 0),
    'average_points', (select average_points from user_totals),
    'best_weekend', coalesce((select to_jsonb(best) from best), '{}'::jsonb),
    'worst_weekend', coalesce((select to_jsonb(worst) from worst), '{}'::jsonb),
    'prediction_count', coalesce((select prediction_count from picks), 0),
    'completed_rounds', coalesce((select count(*)::int from rows), 0),
    'total_rounds', coalesce((select total_rounds from league_meta), 0),
    'member_count', coalesce((select member_count from league_meta), 0),
    'leader_score', coalesce((select max(total_score)::int from standings), 0),
    'leader_gap', greatest(coalesce((select max(total_score)::int from standings), 0) - (select total_points from user_totals), 0),
    'league_average_points', coalesce(round(avg(league_scores.total_score)::numeric, 1), 0),
    'trend', (select items from trend)
  ) into v_result
  from league_scores;

  return coalesce(v_result, jsonb_build_object(
    'total_points', 0,
    'current_rank', 0,
    'average_points', 0,
    'best_weekend', '{}'::jsonb,
    'worst_weekend', '{}'::jsonb,
    'prediction_count', 0,
    'completed_rounds', 0,
    'total_rounds', 0,
    'member_count', 0,
    'leader_score', 0,
    'leader_gap', 0,
    'league_average_points', 0,
    'trend', '[]'::jsonb
  ));
end;
$$;

grant execute on function public.league_user_overview_stats(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
