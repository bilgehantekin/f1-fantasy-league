-- Mock kullanıcılar + ligleri doldurur.
-- Idempotent: fixed UUID'lerle yazıldı.
-- Şifre: mock (tüm mock kullanıcılar için)

BEGIN;

-- 0) Public 'Genel Lig 2026' ligini ve üyeliklerini sil
DELETE FROM leagues WHERE type = 'public';

-- 1) test_arkadaslar_ligi_history.sql için gereken 'bilge' prefix'li kullanıcılar
INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
VALUES
  ('bbbb0001-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'bilge@mock.local',         crypt('mock', gen_salt('bf')), now(), '{"username":"bilge"}',         now(), now()),
  ('bbbb0002-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bilgehan@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"bilgehan"}',      now(), now()),
  ('bbbb0003-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'bilgeee@mock.local',       crypt('mock', gen_salt('bf')), now(), '{"username":"bilgeee"}',       now(), now()),
  ('bbbb0004-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'bilgehannnnn@mock.local',  crypt('mock', gen_salt('bf')), now(), '{"username":"bilgehannnnn"}',  now(), now()),
  ('bbbb0005-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'bilgeeee@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"bilgeeee"}',      now(), now())
ON CONFLICT (id) DO NOTHING;

-- 2) Diğer mock kullanıcılar
INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
VALUES
  ('11111111-1111-1111-1111-111111110001', 'authenticated', 'authenticated', 'maxfan47@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"maxfan47"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110002', 'authenticated', 'authenticated', 'leclerc16@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"leclerc16"}',     now(), now()),
  ('11111111-1111-1111-1111-111111110003', 'authenticated', 'authenticated', 'pitcrew@mock.local',       crypt('mock', gen_salt('bf')), now(), '{"username":"pitcrew"}',       now(), now()),
  ('11111111-1111-1111-1111-111111110004', 'authenticated', 'authenticated', 'norris04@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"norris04"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110005', 'authenticated', 'authenticated', 'racergirl@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"racergirl"}',     now(), now()),
  ('11111111-1111-1111-1111-111111110006', 'authenticated', 'authenticated', 'apexhunter@mock.local',    crypt('mock', gen_salt('bf')), now(), '{"username":"apexhunter"}',    now(), now()),
  ('11111111-1111-1111-1111-111111110007', 'authenticated', 'authenticated', 'monzaqueen@mock.local',    crypt('mock', gen_salt('bf')), now(), '{"username":"monzaqueen"}',    now(), now()),
  ('11111111-1111-1111-1111-111111110008', 'authenticated', 'authenticated', 'tifosi27@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"tifosi27"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110009', 'authenticated', 'authenticated', 'silverstone@mock.local',   crypt('mock', gen_salt('bf')), now(), '{"username":"silverstone"}',   now(), now()),
  ('11111111-1111-1111-1111-111111110010', 'authenticated', 'authenticated', 'paddockclub@mock.local',   crypt('mock', gen_salt('bf')), now(), '{"username":"paddockclub"}',   now(), now()),
  ('11111111-1111-1111-1111-111111110011', 'authenticated', 'authenticated', 'undercut@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"undercut"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110012', 'authenticated', 'authenticated', 'pole_position@mock.local', crypt('mock', gen_salt('bf')), now(), '{"username":"pole_position"}', now(), now())
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- Doğrulama
SELECT 'profile sayısı' AS metrik, COUNT(*)::text FROM profiles;
