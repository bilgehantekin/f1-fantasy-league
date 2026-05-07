-- Restore local test accounts after a local Supabase reset.
--
-- Recreates the known GridCall test users with login:
--   email: <username>@gmail.com
--   password: 12345678
--
-- The script removes the generic demo accounts created by older mock seeds so
-- Arkadaşlar Ligi returns to the expected 10-person test set.

begin;

delete from auth.users
where id in (
  '11111111-1111-1111-1111-111111110001',
  '11111111-1111-1111-1111-111111110002',
  '11111111-1111-1111-1111-111111110003',
  '11111111-1111-1111-1111-111111110004',
  '11111111-1111-1111-1111-111111110005',
  '11111111-1111-1111-1111-111111110006',
  '11111111-1111-1111-1111-111111110007',
  '11111111-1111-1111-1111-111111110008',
  '11111111-1111-1111-1111-111111110009',
  '11111111-1111-1111-1111-111111110010',
  '11111111-1111-1111-1111-111111110011',
  '11111111-1111-1111-1111-111111110012'
);

with users(id, username) as (
  values
    ('bbbb0001-0000-0000-0000-000000000001'::uuid, 'bilge'),
    ('bbbb0002-0000-0000-0000-000000000002'::uuid, 'bilgehan'),
    ('bbbb0003-0000-0000-0000-000000000003'::uuid, 'bilgeee'),
    ('bbbb0004-0000-0000-0000-000000000004'::uuid, 'bilgehannnnn'),
    ('bbbb0005-0000-0000-0000-000000000005'::uuid, 'bilgeeee'),
    ('bbbb0006-0000-0000-0000-000000000006'::uuid, 'bilgehannn'),
    ('bbbb0007-0000-0000-0000-000000000007'::uuid, 'bilgehannnn'),
    ('bbbb0008-0000-0000-0000-000000000008'::uuid, 'kyoton'),
    ('bbbb0009-0000-0000-0000-000000000009'::uuid, 'kyoton123'),
    ('bbbb0010-0000-0000-0000-000000000010'::uuid, 'torosdarak')
)
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  is_sso_user,
  is_anonymous
)
select
  '00000000-0000-0000-0000-000000000000'::uuid,
  id,
  'authenticated',
  'authenticated',
  username || '@gmail.com',
  crypt('12345678', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('username', username),
  now(),
  now(),
  false,
  false
from users
on conflict (id) do update
set email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    updated_at = now(),
    is_sso_user = false,
    is_anonymous = false;

with users(id, username) as (
  values
    ('bbbb0001-0000-0000-0000-000000000001'::uuid, 'bilge'),
    ('bbbb0002-0000-0000-0000-000000000002'::uuid, 'bilgehan'),
    ('bbbb0003-0000-0000-0000-000000000003'::uuid, 'bilgeee'),
    ('bbbb0004-0000-0000-0000-000000000004'::uuid, 'bilgehannnnn'),
    ('bbbb0005-0000-0000-0000-000000000005'::uuid, 'bilgeeee'),
    ('bbbb0006-0000-0000-0000-000000000006'::uuid, 'bilgehannn'),
    ('bbbb0007-0000-0000-0000-000000000007'::uuid, 'bilgehannnn'),
    ('bbbb0008-0000-0000-0000-000000000008'::uuid, 'kyoton'),
    ('bbbb0009-0000-0000-0000-000000000009'::uuid, 'kyoton123'),
    ('bbbb0010-0000-0000-0000-000000000010'::uuid, 'torosdarak')
)
insert into auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at,
  last_sign_in_at
)
select
  id,
  username || '@gmail.com',
  id,
  jsonb_build_object(
    'sub', id::text,
    'email', username || '@gmail.com',
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  now(),
  now(),
  now()
from users
on conflict (provider_id, provider) do update
set user_id = excluded.user_id,
    identity_data = excluded.identity_data,
    updated_at = now();

with users(id, username) as (
  values
    ('bbbb0001-0000-0000-0000-000000000001'::uuid, 'bilge'),
    ('bbbb0002-0000-0000-0000-000000000002'::uuid, 'bilgehan'),
    ('bbbb0003-0000-0000-0000-000000000003'::uuid, 'bilgeee'),
    ('bbbb0004-0000-0000-0000-000000000004'::uuid, 'bilgehannnnn'),
    ('bbbb0005-0000-0000-0000-000000000005'::uuid, 'bilgeeee'),
    ('bbbb0006-0000-0000-0000-000000000006'::uuid, 'bilgehannn'),
    ('bbbb0007-0000-0000-0000-000000000007'::uuid, 'bilgehannnn'),
    ('bbbb0008-0000-0000-0000-000000000008'::uuid, 'kyoton'),
    ('bbbb0009-0000-0000-0000-000000000009'::uuid, 'kyoton123'),
    ('bbbb0010-0000-0000-0000-000000000010'::uuid, 'torosdarak')
)
insert into public.profiles (id, username, onboarding_completed)
select id, username, true
from users
on conflict (id) do update
set username = excluded.username,
    onboarding_completed = true,
    updated_at = now();

commit;

select 'restore users' as metrik, count(*)::int as adet
from public.profiles;

select username, email
from public.profiles p
join auth.users u on u.id = p.id
order by lower(username);
