-- 0051: Joker sorularının türünü ayırt etmek için `kind` sütunu ekle.
-- 'choice' = klasik çoktan seçmeli (Evet/Hayır gibi), prediction.joker_option
--   string olarak label'ı taşır.
-- 'driver' = sürücü seçilen sorular (P4-P22, en hızlı tur, ilk turun lideri),
--   prediction.joker_option o sürücünün UUID'sini taşır.

alter table public.joker_questions
  add column if not exists kind text not null default 'choice'
  check (kind in ('choice', 'driver'));
