-- Demo verisi: Miami GP'yi LIVE state'e al, live_positions doldur,
-- Canadian GP için joker question ekle (TAHMINE AÇIK'ı görmek için).
-- Tekrar çalıştırılabilir (idempotent).

BEGIN;

-- 1) Miami (round 6) -> LIVE
UPDATE races
   SET status = 'live'
 WHERE season_id = 2026 AND round = 6;

-- 2) live_positions: Miami için top 20 driver
DELETE FROM live_positions
 WHERE race_id = (SELECT id FROM races WHERE season_id=2026 AND round=6);

WITH miami AS (
  SELECT id FROM races WHERE season_id=2026 AND round=6
),
ordered AS (
  SELECT id AS driver_id,
         ROW_NUMBER() OVER (ORDER BY full_name) AS pos
    FROM drivers
   WHERE season_id = 2026
)
INSERT INTO live_positions (race_id, driver_id, position, gap_to_leader_ms, last_lap_ms, in_pit, status, updated_at)
SELECT (SELECT id FROM miami),
       o.driver_id,
       o.pos,
       (o.pos - 1) * 1500,
       80000 + (o.pos * 120),
       false,
       CASE WHEN o.pos > 20 THEN 'retired' ELSE 'running' END,
       now()
  FROM ordered o
 WHERE o.pos <= 22;

-- 3) Canadian GP (round 7) için joker question
INSERT INTO joker_questions (race_id, text, options, points)
SELECT id, 'Yarışta safety car çıkar mı?', '["Evet","Hayır"]'::jsonb, 12
  FROM races WHERE season_id=2026 AND round=7
ON CONFLICT (race_id) DO NOTHING;

-- 4) Canadian GP lock_at'i 2 gün ileri al (TAHMINE AÇIK görünmesi için)
UPDATE races
   SET lock_at = now() + interval '2 days'
 WHERE season_id=2026 AND round=7;

COMMIT;

-- Doğrulama
SELECT round, name, status, lock_at FROM races WHERE season_id=2026 ORDER BY round;
SELECT COUNT(*) AS live_pos_count FROM live_positions
 WHERE race_id = (SELECT id FROM races WHERE season_id=2026 AND round=6);
