-- pgTAP - premium entitlement, league limits, favorites, and stats hardening.
begin;
select plan(38);

select set_config('app.enable_premium_league_limits', 'true', true);

insert into public.seasons (id, is_active) values (9997, false);

insert into public.teams (id, season_id, code, name)
values ('40000000-0000-0000-0000-000000000001', 9997, 'PRM', 'Premium Test Team');

insert into public.drivers (id, season_id, code, full_name, team_id)
values
  ('40000000-0000-0000-0000-000000000011', 9997, 'P01', 'Premium Driver 1', '40000000-0000-0000-0000-000000000001'),
  ('40000000-0000-0000-0000-000000000012', 9997, 'P02', 'Premium Driver 2', '40000000-0000-0000-0000-000000000001');

insert into public.races (id, season_id, round, name, circuit, qualifying_at, race_at)
values
  ('40000000-0000-0000-0000-000000000101', 9997, 1, 'Premium Future', 'Test', now() + interval '7 days', now() + interval '8 days');

insert into auth.users (id, email, raw_user_meta_data)
values
  ('40000000-0000-0000-0000-000000000201', 'premium-free-create@example.com', '{"username":"free_create"}'::jsonb),
  ('40000000-0000-0000-0000-000000000202', 'premium-free-join@example.com', '{"username":"free_join"}'::jsonb),
  ('40000000-0000-0000-0000-000000000203', 'premium-paid@example.com', '{"username":"paid_user"}'::jsonb),
  ('40000000-0000-0000-0000-000000000204', 'premium-other@example.com', '{"username":"other_user"}'::jsonb),
  ('40000000-0000-0000-0000-000000000205', 'premium-overlimit@example.com', '{"username":"overlimit_user"}'::jsonb),
  ('40000000-0000-0000-0000-000000000206', 'premium-nonmember@example.com', '{"username":"nonmember_user"}'::jsonb)
on conflict (id) do nothing;

insert into public.profiles (id, username)
values
  ('40000000-0000-0000-0000-000000000201', 'free_create'),
  ('40000000-0000-0000-0000-000000000202', 'free_join'),
  ('40000000-0000-0000-0000-000000000203', 'paid_user'),
  ('40000000-0000-0000-0000-000000000204', 'other_user'),
  ('40000000-0000-0000-0000-000000000205', 'overlimit_user'),
  ('40000000-0000-0000-0000-000000000206', 'nonmember_user')
on conflict (id) do nothing;

insert into public.user_entitlements (
  user_id, entitlement, source, product_id, original_transaction_id, status,
  current_period_start, current_period_end
) values
  ('40000000-0000-0000-0000-000000000203', 'premium', 'revenuecat', 'gridcall_premium_annual', 'paid-active', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('40000000-0000-0000-0000-000000000204', 'premium', 'revenuecat', 'gridcall_premium_monthly', 'other-active', 'active', now() - interval '1 day', now() + interval '30 days');

-- Entitlement RLS and status logic.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is((select count(*)::int from public.user_entitlements), 1, 'user can read only their own entitlement');

prepare self_entitlement_insert as
  insert into public.user_entitlements (user_id, entitlement, source, status, current_period_end)
  values ('40000000-0000-0000-0000-000000000203', 'premium', 'revenuecat', 'active', now() + interval '1 day');
select throws_ok('self_entitlement_insert', '42501', null, 'user cannot insert own entitlement directly');

update public.user_entitlements set status = 'expired'
where user_id = '40000000-0000-0000-0000-000000000203';
select is(
  (select status from public.user_entitlements where user_id = '40000000-0000-0000-0000-000000000203'),
  'active',
  'user cannot update own entitlement directly'
);

delete from public.user_entitlements
where user_id = '40000000-0000-0000-0000-000000000203';
select is(
  (select count(*)::int from public.user_entitlements where user_id = '40000000-0000-0000-0000-000000000203'),
  1,
  'user cannot delete own entitlement directly'
);

select is(public.current_user_is_premium(), true, 'active future entitlement is premium');
reset role;

update public.user_entitlements set status = 'trialing'
where user_id = '40000000-0000-0000-0000-000000000203';
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.current_user_is_premium(), true, 'trialing future entitlement is premium');
reset role;

update public.user_entitlements set status = 'grace_period'
where user_id = '40000000-0000-0000-0000-000000000203';
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.current_user_is_premium(), true, 'grace period future entitlement is premium');
reset role;

update public.user_entitlements set status = 'expired'
where user_id = '40000000-0000-0000-0000-000000000203';
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.current_user_is_premium(), false, 'expired entitlement is not premium');
reset role;

update public.user_entitlements set status = 'canceled'
where user_id = '40000000-0000-0000-0000-000000000203';
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.current_user_is_premium(), false, 'canceled entitlement is not premium');
reset role;

update public.user_entitlements
set status = 'active', current_period_end = now() - interval '1 minute'
where user_id = '40000000-0000-0000-0000-000000000203';
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.current_user_is_premium(), false, 'past period entitlement is not premium');
reset role;

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000201', true);
set local role authenticated;
select is(public.current_user_is_premium(), false, 'missing entitlement is not premium');
reset role;

update public.user_entitlements
set status = 'active', current_period_end = now() + interval '30 days'
where user_id = '40000000-0000-0000-0000-000000000203';

-- Free create limit.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000201', true);
set local role authenticated;
prepare free_create_1 as select public.create_league('Free Create 1', 9997::smallint);
prepare free_create_2 as select public.create_league('Free Create 2', 9997::smallint);
prepare free_create_3 as select public.create_league('Free Create 3', 9997::smallint);
select lives_ok('free_create_1', 'free user can create first active league');
select lives_ok('free_create_2', 'free user can create second active league');
select throws_like('free_create_3', '%FREE_LEAGUE_LIMIT_REACHED%', 'free user cannot create third active league');
reset role;

-- Free join limit.
insert into public.leagues (id, name, owner_id, invite_code, season_id)
values
  ('40000000-0000-0000-0000-000000000301', 'Join Target 1', '40000000-0000-0000-0000-000000000204', 'PRM001AA', 9997),
  ('40000000-0000-0000-0000-000000000302', 'Join Target 2', '40000000-0000-0000-0000-000000000204', 'PRM002AA', 9997),
  ('40000000-0000-0000-0000-000000000303', 'Join Target 3', '40000000-0000-0000-0000-000000000204', 'PRM003AA', 9997);

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000202', true);
set local role authenticated;
prepare free_join_1 as select public.join_league_by_code('PRM001AA');
prepare free_join_2 as select public.join_league_by_code('PRM002AA');
prepare free_join_3 as select public.join_league_by_code('PRM003AA');
select lives_ok('free_join_1', 'free user can join first active league');
select lives_ok('free_join_2', 'free user can join second active league');
select throws_like('free_join_3', '%FREE_LEAGUE_LIMIT_REACHED%', 'free user cannot join third active league');
reset role;

-- Premium 10/11 limit.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
prepare premium_create_1 as select public.create_league('Premium Create 1', 9997::smallint);
prepare premium_create_2 as select public.create_league('Premium Create 2', 9997::smallint);
prepare premium_create_3 as select public.create_league('Premium Create 3', 9997::smallint);
prepare premium_create_4 as select public.create_league('Premium Create 4', 9997::smallint);
prepare premium_create_5 as select public.create_league('Premium Create 5', 9997::smallint);
prepare premium_create_6 as select public.create_league('Premium Create 6', 9997::smallint);
prepare premium_create_7 as select public.create_league('Premium Create 7', 9997::smallint);
prepare premium_create_8 as select public.create_league('Premium Create 8', 9997::smallint);
prepare premium_create_9 as select public.create_league('Premium Create 9', 9997::smallint);
prepare premium_create_10 as select public.create_league('Premium Create 10', 9997::smallint);
prepare premium_create_11 as select public.create_league('Premium Create 11', 9997::smallint);
select lives_ok('premium_create_1', 'premium user can create active league 1');
select lives_ok('premium_create_2', 'premium user can create active league 2');
select lives_ok('premium_create_3', 'premium user can create active league 3');
select lives_ok('premium_create_4', 'premium user can create active league 4');
select lives_ok('premium_create_5', 'premium user can create active league 5');
select lives_ok('premium_create_6', 'premium user can create active league 6');
select lives_ok('premium_create_7', 'premium user can create active league 7');
select lives_ok('premium_create_8', 'premium user can create active league 8');
select lives_ok('premium_create_9', 'premium user can create active league 9');
select lives_ok('premium_create_10', 'premium user can create active league 10');
select throws_like('premium_create_11', '%FREE_LEAGUE_LIMIT_REACHED%', 'premium user cannot create active league 11');
reset role;

-- Existing over-limit users remain, but cannot add more.
insert into public.leagues (id, name, owner_id, invite_code, season_id)
values
  ('40000000-0000-0000-0000-000000000304', 'Over Limit 1', '40000000-0000-0000-0000-000000000204', 'PRM004AA', 9997),
  ('40000000-0000-0000-0000-000000000305', 'Over Limit 2', '40000000-0000-0000-0000-000000000204', 'PRM005AA', 9997),
  ('40000000-0000-0000-0000-000000000306', 'Over Limit 3', '40000000-0000-0000-0000-000000000204', 'PRM006AA', 9997);
insert into public.league_memberships (league_id, user_id, role)
values
  ('40000000-0000-0000-0000-000000000304', '40000000-0000-0000-0000-000000000205', 'member'),
  ('40000000-0000-0000-0000-000000000305', '40000000-0000-0000-0000-000000000205', 'member'),
  ('40000000-0000-0000-0000-000000000306', '40000000-0000-0000-0000-000000000205', 'member');
select is(public.active_league_count_for('40000000-0000-0000-0000-000000000205'::uuid, 9997::smallint), 3, 'existing free user over limit is not removed');
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000205', true);
set local role authenticated;
prepare overlimit_create as select public.create_league('Over Limit Create', 9997::smallint);
select throws_like('overlimit_create', '%FREE_LEAGUE_LIMIT_REACHED%', 'existing over-limit free user cannot add another league');
reset role;

-- Direct membership path also enforces the limit.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000202', true);
set local role authenticated;
prepare direct_membership_insert as
  insert into public.league_memberships (league_id, user_id, role)
  values ('40000000-0000-0000-0000-000000000303', '40000000-0000-0000-0000-000000000202', 'member');
select throws_ok('direct_membership_insert', '42501', null, 'direct membership insert enforces active league limit');
reset role;

-- Favorites.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is(public.set_league_favorite((select id from public.leagues where owner_id = '40000000-0000-0000-0000-000000000203' limit 1), true), true, 'premium member can favorite own league');
select is(public.set_league_favorite((select id from public.leagues where owner_id = '40000000-0000-0000-0000-000000000203' limit 1), false), false, 'premium member can unfavorite own league');
reset role;

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000202', true);
set local role authenticated;
prepare free_favorite as select public.set_league_favorite('40000000-0000-0000-0000-000000000301', true);
select throws_like('free_favorite', '%PREMIUM_REQUIRED%', 'free member cannot favorite league');
reset role;

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000206', true);
set local role authenticated;
prepare nonmember_favorite as select public.set_league_favorite('40000000-0000-0000-0000-000000000301', true);
select throws_ok('nonmember_favorite', '42501', null, 'non-member cannot favorite league');
reset role;

-- Premium stats.
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000203', true);
set local role authenticated;
select is((public.league_user_overview_stats((select id from public.leagues where owner_id = '40000000-0000-0000-0000-000000000203' limit 1))->>'total_points')::int, 0, 'premium member can access empty detailed league stats');
reset role;

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000202', true);
set local role authenticated;
prepare free_stats as select public.league_user_overview_stats('40000000-0000-0000-0000-000000000301');
select throws_like('free_stats', '%PREMIUM_REQUIRED%', 'free user cannot access premium stats');
reset role;

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000206', true);
set local role authenticated;
prepare nonmember_stats as select public.league_user_overview_stats('40000000-0000-0000-0000-000000000301');
select throws_ok('nonmember_stats', '42501', null, 'non-member cannot access league stats');
reset role;

select * from finish();
rollback;
