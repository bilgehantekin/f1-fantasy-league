-- pgTAP - prediction RLS and league membership rules
begin;
select plan(13);

insert into public.seasons (id, is_active)
values (9998, false);

insert into public.teams (id, season_id, code, name)
values ('10000000-0000-0000-0000-000000000001', 9998, 'RLS', 'RLS Team');

insert into public.drivers (id, season_id, code, full_name, team_id)
values
  ('10000000-0000-0000-0000-000000000011', 9998, 'R01', 'RLS Driver 1', '10000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000012', 9998, 'R02', 'RLS Driver 2', '10000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000013', 9998, 'R03', 'RLS Driver 3', '10000000-0000-0000-0000-000000000001');

insert into public.races (id, season_id, round, name, circuit, qualifying_at, race_at)
values
  ('10000000-0000-0000-0000-000000000101', 9998, 1, 'RLS Future', 'Test', now() + interval '7 days', now() + interval '8 days'),
  ('10000000-0000-0000-0000-000000000102', 9998, 2, 'RLS Locked', 'Test', now() - interval '2 days', now() - interval '1 day');

insert into auth.users (id, email)
values
  ('10000000-0000-0000-0000-000000000201', 'rls-owner@example.com'),
  ('20000000-0000-0000-0000-000000000202', 'rls-member@example.com'),
  ('30000000-0000-0000-0000-000000000203', 'rls-outsider@example.com')
on conflict (id) do nothing;

insert into public.profiles (id, username)
values
  ('10000000-0000-0000-0000-000000000201', 'rls_owner'),
  ('20000000-0000-0000-0000-000000000202', 'rls_member'),
  ('30000000-0000-0000-0000-000000000203', 'rls_outsider')
on conflict (id) do nothing;

insert into public.leagues (id, name, owner_id, invite_code, season_id)
values
  ('10000000-0000-0000-0000-000000000301', 'RLS League', '10000000-0000-0000-0000-000000000201', 'RLS001', 9998),
  ('10000000-0000-0000-0000-000000000302', 'Other RLS League', '30000000-0000-0000-0000-000000000203', 'RLS002', 9998);

insert into public.league_memberships (league_id, user_id, role)
values
  ('10000000-0000-0000-0000-000000000301', '10000000-0000-0000-0000-000000000201', 'admin'),
  ('10000000-0000-0000-0000-000000000301', '20000000-0000-0000-0000-000000000202', 'member'),
  ('10000000-0000-0000-0000-000000000302', '30000000-0000-0000-0000-000000000203', 'admin')
on conflict do nothing;

prepare anon_insert as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  values (
    '10000000-0000-0000-0000-000000000201',
    '10000000-0000-0000-0000-000000000301',
    '10000000-0000-0000-0000-000000000101',
    '10000000-0000-0000-0000-000000000011'
  );
set local role anon;
select throws_ok('anon_insert', '42501', null, 'anonymous users cannot insert predictions');
reset role;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000201', true);
set local role authenticated;

prepare owner_insert as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id, p1_id, p2_id, p3_id, dnf_count, joker_option)
  values (
    '10000000-0000-0000-0000-000000000201',
    '10000000-0000-0000-0000-000000000301',
    '10000000-0000-0000-0000-000000000101',
    '10000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000012',
    '10000000-0000-0000-0000-000000000013',
    2,
    'yes'
  );
select lives_ok('owner_insert', 'league member can insert own prediction before lock');

prepare nonmember_insert as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  values (
    '10000000-0000-0000-0000-000000000201',
    '10000000-0000-0000-0000-000000000302',
    '10000000-0000-0000-0000-000000000101',
    '10000000-0000-0000-0000-000000000011'
  );
select throws_ok('nonmember_insert', '42501', null, 'member cannot write into a league they do not belong to');

reset role;
insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
values (
  '20000000-0000-0000-0000-000000000202',
  '10000000-0000-0000-0000-000000000301',
  '10000000-0000-0000-0000-000000000101',
  '10000000-0000-0000-0000-000000000012'
);

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000201', true);
set local role authenticated;
select is(
  (select count(*)::int from public.predictions where user_id = '20000000-0000-0000-0000-000000000202'),
  0,
  'member cannot read another member prediction before lock'
);

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000203', true);
select is(
  (select count(*)::int from public.predictions where league_id = '10000000-0000-0000-0000-000000000301'),
  0,
  'outsider cannot read predictions from another league'
);

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000202', true);
update public.predictions
set winner_driver_id = '10000000-0000-0000-0000-000000000013'
where user_id = '10000000-0000-0000-0000-000000000201';
reset role;
select is(
  (select winner_driver_id from public.predictions
    where user_id = '10000000-0000-0000-0000-000000000201'
      and race_id = '10000000-0000-0000-0000-000000000101'),
  '10000000-0000-0000-0000-000000000011'::uuid,
  'member cannot update another user prediction'
);

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000201', true);
set local role authenticated;
prepare locked_insert as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  values (
    '10000000-0000-0000-0000-000000000201',
    '10000000-0000-0000-0000-000000000301',
    '10000000-0000-0000-0000-000000000102',
    '10000000-0000-0000-0000-000000000011'
  );
select throws_ok('locked_insert', 'P0001', null, 'locked race rejects prediction insert at DB level');

reset role;
alter table public.predictions disable trigger predictions_enforce_lock;
insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
values (
  '10000000-0000-0000-0000-000000000201',
  '10000000-0000-0000-0000-000000000301',
  '10000000-0000-0000-0000-000000000102',
  '10000000-0000-0000-0000-000000000011'
);
alter table public.predictions enable trigger predictions_enforce_lock;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000201', true);
set local role authenticated;
prepare locked_update as
  update public.predictions
  set winner_driver_id = '10000000-0000-0000-0000-000000000012'
  where user_id = '10000000-0000-0000-0000-000000000201'
    and race_id = '10000000-0000-0000-0000-000000000102';
select throws_ok('locked_update', 'P0001', null, 'locked race rejects prediction update at DB level');

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000202', true);
set local role authenticated;
prepare nonowner_rename as
  select public.update_league_name(
    '10000000-0000-0000-0000-000000000301',
    'Hacked League'
  );
select throws_ok('nonowner_rename', '42501', null, 'non-owner cannot update league settings');

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000201', true);
prepare owner_rename as
  select public.update_league_name(
    '10000000-0000-0000-0000-000000000301',
    'Owner Renamed League'
  );
select lives_ok('owner_rename', 'owner can update league settings');

reset role;
select is(
  (select name from public.leagues where id = '10000000-0000-0000-0000-000000000301'),
  'Owner Renamed League',
  'league name changed only through owner RPC'
);

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000203', true);
set local role authenticated;
prepare invalid_join_code as
  select public.join_league_by_code('NOPE00');
select throws_ok('invalid_join_code', 'P0002', null, 'invalid private league invite code is rejected server-side');

select set_config('request.jwt.claims', '{"role":"authenticated","sub":"20000000-0000-0000-0000-000000000202"}', true);
select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000202', true);
update public.profiles
set tier = 'premium'
where id = '20000000-0000-0000-0000-000000000202';
reset role;
select is(
  (select tier::text from public.profiles where id = '20000000-0000-0000-0000-000000000202'),
  'free',
  'authenticated users cannot grant themselves premium tier'
);

select * from finish();
rollback;
