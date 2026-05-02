-- Mock kullanıcılar + ligleri doldurur + bilge için rozet/skor üretir.
-- "Genel Lig 2026"'yı temizler.
-- Idempotent: fixed UUID'lerle yazıldı.

BEGIN;

-- 0) Public 'Genel Lig 2026' ligini ve üyeliklerini sil
DELETE FROM leagues WHERE type = 'public';

-- 1) Mock auth.users (handle_new_user trigger profiles tablosunu doldurur).
-- raw_user_meta_data->>'username' aktarıyoruz ki collision olmasın.
INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
VALUES
  ('11111111-1111-1111-1111-111111110001', 'authenticated', 'authenticated', 'maxfan47@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"maxfan47"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110002', 'authenticated', 'authenticated', 'leclerc16@mock.local',    crypt('mock', gen_salt('bf')), now(), '{"username":"leclerc16"}',     now(), now()),
  ('11111111-1111-1111-1111-111111110003', 'authenticated', 'authenticated', 'pitcrew@mock.local',      crypt('mock', gen_salt('bf')), now(), '{"username":"pitcrew"}',       now(), now()),
  ('11111111-1111-1111-1111-111111110004', 'authenticated', 'authenticated', 'norris04@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"norris04"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110005', 'authenticated', 'authenticated', 'racergirl@mock.local',    crypt('mock', gen_salt('bf')), now(), '{"username":"racergirl"}',     now(), now()),
  ('11111111-1111-1111-1111-111111110006', 'authenticated', 'authenticated', 'apexhunter@mock.local',   crypt('mock', gen_salt('bf')), now(), '{"username":"apexhunter"}',    now(), now()),
  ('11111111-1111-1111-1111-111111110007', 'authenticated', 'authenticated', 'monzaqueen@mock.local',   crypt('mock', gen_salt('bf')), now(), '{"username":"monzaqueen"}',    now(), now()),
  ('11111111-1111-1111-1111-111111110008', 'authenticated', 'authenticated', 'tifosi27@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"tifosi27"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110009', 'authenticated', 'authenticated', 'silverstone@mock.local',  crypt('mock', gen_salt('bf')), now(), '{"username":"silverstone"}',   now(), now()),
  ('11111111-1111-1111-1111-111111110010', 'authenticated', 'authenticated', 'paddockclub@mock.local',  crypt('mock', gen_salt('bf')), now(), '{"username":"paddockclub"}',   now(), now()),
  ('11111111-1111-1111-1111-111111110011', 'authenticated', 'authenticated', 'undercut@mock.local',     crypt('mock', gen_salt('bf')), now(), '{"username":"undercut"}',      now(), now()),
  ('11111111-1111-1111-1111-111111110012', 'authenticated', 'authenticated', 'pole_position@mock.local',crypt('mock', gen_salt('bf')), now(), '{"username":"pole_position"}', now(), now())
ON CONFLICT (id) DO NOTHING;

-- 3) Mock kullanıcıları bilge'nin iki özel ligine üye yap
INSERT INTO league_memberships (league_id, user_id, role, joined_at)
SELECT l.id, p.id, 'member', now() - (random() * interval '20 days')
  FROM leagues l
  CROSS JOIN profiles p
 WHERE l.owner_id = '75faa856-9389-41a0-ab74-7b4ee9483765'
   AND l.type = 'private'
   AND p.id::text LIKE '11111111-%'
ON CONFLICT (league_id, user_id) DO NOTHING;

-- 4) Bitmiş yarışlar için tüm kullanıcılara skorlu predictions üret.
-- enforce_prediction_lock trigger'ı geçmiş yarışlara yazmayı engelliyor; replica modu trigger'ları atlatır.
SET session_replication_role = 'replica';

INSERT INTO predictions (user_id, race_id, score, dnf_count)
SELECT
  p.id,
  r.id,
  CASE
    WHEN p.id = '75faa856-9389-41a0-ab74-7b4ee9483765' THEN 35 + (r.round * 3) + ((random() * 10)::int)
    ELSE 12 + ((random() * 40)::int)
  END,
  ((random() * 4)::int)
  FROM races r
  CROSS JOIN profiles p
 WHERE r.season_id = 2026 AND r.status = 'finished'
ON CONFLICT (user_id, race_id) DO UPDATE SET score = EXCLUDED.score;

SET session_replication_role = 'origin';

-- 5) Bilge'ye 5 rozet (5 farklı bitmiş yarıştan)
WITH wanted AS (
  SELECT id, code,
         ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM badges
   WHERE code IN ('pole_caller', 'fastest_caller', 'joker_master', 'bullseye_podium', 'three_in_row')
),
finished_races AS (
  SELECT id, round, race_at,
         ROW_NUMBER() OVER (ORDER BY round) AS rn
    FROM races
   WHERE season_id = 2026 AND status = 'finished'
)
INSERT INTO user_badges (user_id, badge_id, race_id, awarded_at)
SELECT
  '75faa856-9389-41a0-ab74-7b4ee9483765',
  w.id,
  fr.id,
  fr.race_at + interval '4 hours'
  FROM wanted w
  JOIN finished_races fr ON fr.rn = w.rn
ON CONFLICT DO NOTHING;

COMMIT;

-- Doğrulama
SELECT 'profile sayısı' AS metrik, COUNT(*)::text FROM profiles;
SELECT 'lig üyelikleri' AS metrik, l.name, COUNT(lm.user_id)::text AS uye_sayi
  FROM leagues l LEFT JOIN league_memberships lm ON lm.league_id = l.id
 GROUP BY l.id, l.name;
SELECT 'rozet kazanılmış' AS metrik, COUNT(*)::text FROM user_badges
 WHERE user_id='75faa856-9389-41a0-ab74-7b4ee9483765';
SELECT 'skorlu tahmin' AS metrik, COUNT(*)::text FROM predictions WHERE score IS NOT NULL;
