-- 0046: Production safety fixes surfaced by db lint.

create or replace function public.generate_invite_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
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

  raise exception 'Could not generate unique invite code';
end$$;

create or replace function public.process_account_deletion(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    raise exception 'p_user_id required';
  end if;

  delete from public.predictions where user_id = p_user_id;
  delete from public.sprint_predictions where user_id = p_user_id;

  delete from public.league_memberships where user_id = p_user_id;

  delete from public.leagues l
  where l.owner_id = p_user_id
    and not exists (
      select 1
      from public.league_memberships m
      where m.league_id = l.id
    );

  update public.leagues l
  set owner_id = (
    select m.user_id
    from public.league_memberships m
    where m.league_id = l.id
    order by m.joined_at asc
    limit 1
  )
  where l.owner_id = p_user_id;

  if to_regclass('public.user_badges') is not null then
    execute 'delete from public.user_badges where user_id = $1' using p_user_id;
  end if;

  if to_regclass('public.notification_preferences') is not null then
    execute 'delete from public.notification_preferences where user_id = $1' using p_user_id;
  end if;

  if to_regclass('public.subscriptions') is not null then
    execute 'delete from public.subscriptions where user_id = $1' using p_user_id;
  end if;

  if to_regclass('public.user_entitlements') is not null then
    execute 'delete from public.user_entitlements where user_id = $1' using p_user_id;
  end if;

  if to_regclass('public.league_favorites') is not null then
    execute 'delete from public.league_favorites where user_id = $1' using p_user_id;
  end if;

  delete from public.profiles where id = p_user_id;
end;
$$;

revoke all on function public.process_account_deletion(uuid) from public;
grant execute on function public.process_account_deletion(uuid) to service_role;
