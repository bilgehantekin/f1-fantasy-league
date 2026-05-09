-- 0047: Keep account deletion lint-clean by removing a stale optional table
-- branch. Notification preferences currently live in app local storage, not in
-- public.notification_preferences.

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
