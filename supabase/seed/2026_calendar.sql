-- PitWall — sezon başlatma (boş)
-- Gerçek takımlar, sürücüler ve takvim için ingest-openf1 fonksiyonunu
-- season-bootstrap modunda çağırın:
--   curl -s -X POST $URL/functions/v1/ingest-openf1 \
--     -H "Content-Type: application/json" \
--     -d '{"mode":"season-bootstrap","year":2026}'

insert into public.seasons (id, is_active) values (2026, true)
  on conflict (id) do update set is_active = excluded.is_active;
