-- Production preparation: onboarding, league management and weekly summaries.

alter table public.profiles
  add column if not exists onboarding_completed boolean not null default false;

create or replace function public.complete_onboarding(p_username text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_username text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  v_username := nullif(trim(coalesce(p_username, '')), '');
  if v_username is not null then
    if char_length(v_username) < 3 or char_length(v_username) > 24 then
      raise exception 'Username must be between 3 and 24 characters';
    end if;
    update public.profiles
    set username = v_username,
        onboarding_completed = true
    where id = auth.uid();
  else
    update public.profiles
    set onboarding_completed = true
    where id = auth.uid();
  end if;
end$$;

create or replace function public.league_members(p_league_id uuid)
returns table(user_id uuid, username text, role text, joined_at timestamptz)
language sql stable security definer set search_path = public as $$
  select m.user_id, p.username, m.role, m.joined_at
  from public.league_memberships m
  join public.profiles p on p.id = m.user_id
  where m.league_id = p_league_id
    and public.is_member_of(p_league_id)
  order by
    case m.role when 'owner' then 0 when 'admin' then 1 else 2 end,
    m.joined_at;
$$;

create or replace function public.update_league_name(p_league_id uuid, p_name text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.leagues
    where id = p_league_id and owner_id = auth.uid()
  ) then
    raise exception 'Only league owner can update league settings' using errcode = '42501';
  end if;
  update public.leagues
  set name = trim(p_name)
  where id = p_league_id;
end$$;

create or replace function public.regenerate_league_invite_code(p_league_id uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.leagues
    where id = p_league_id and owner_id = auth.uid()
  ) then
    raise exception 'Only league owner can regenerate invite code' using errcode = '42501';
  end if;
  v_code := public.generate_invite_code();
  update public.leagues
  set invite_code = v_code
  where id = p_league_id;
  return v_code;
end$$;

create or replace function public.remove_league_member(p_league_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.leagues
    where id = p_league_id and owner_id = auth.uid()
  ) then
    raise exception 'Only league owner can remove members' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Owner cannot remove themselves';
  end if;
  delete from public.league_memberships
  where league_id = p_league_id and user_id = p_user_id;
end$$;

create or replace function public.transfer_league_ownership(p_league_id uuid, p_new_owner_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.leagues
    where id = p_league_id and owner_id = auth.uid()
  ) then
    raise exception 'Only league owner can transfer ownership' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.league_memberships
    where league_id = p_league_id and user_id = p_new_owner_id
  ) then
    raise exception 'New owner must be a league member';
  end if;

  update public.leagues
  set owner_id = p_new_owner_id
  where id = p_league_id;

  update public.league_memberships
  set role = case
    when user_id = p_new_owner_id then 'owner'
    when user_id = auth.uid() then 'admin'
    else role
  end
  where league_id = p_league_id;
end$$;

create or replace function public.leave_league(p_league_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if exists (
    select 1 from public.leagues
    where id = p_league_id and owner_id = auth.uid()
  ) then
    raise exception 'Owner must transfer ownership before leaving';
  end if;
  delete from public.league_memberships
  where league_id = p_league_id and user_id = auth.uid();
end$$;

create or replace function public.league_weekly_summary(p_league_id uuid, p_race_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with member_predictions as (
    select p.*, pr.username
    from public.predictions p
    join public.league_memberships m on m.user_id = p.user_id
    join public.profiles pr on pr.id = p.user_id
    where m.league_id = p_league_id
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

grant execute on function public.complete_onboarding(text) to authenticated;
grant execute on function public.league_members(uuid) to authenticated;
grant execute on function public.update_league_name(uuid, text) to authenticated;
grant execute on function public.regenerate_league_invite_code(uuid) to authenticated;
grant execute on function public.remove_league_member(uuid, uuid) to authenticated;
grant execute on function public.transfer_league_ownership(uuid, uuid) to authenticated;
grant execute on function public.leave_league(uuid) to authenticated;
grant execute on function public.league_weekly_summary(uuid, uuid) to authenticated;
