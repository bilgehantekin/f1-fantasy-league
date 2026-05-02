-- "Genel Lig" / public lig konsepti kaldırıldı.
-- 0007_public_league_badges.sql'deki trigger ve fonksiyonları siler,
-- mevcut public ligleri temizler.

DROP TRIGGER IF EXISTS on_profile_created_public ON public.profiles;
DROP TRIGGER IF EXISTS profiles_add_to_public_leagues ON public.profiles;
DROP FUNCTION IF EXISTS public.add_to_public_leagues() CASCADE;
DROP FUNCTION IF EXISTS public.ensure_public_league(smallint, uuid) CASCADE;

DELETE FROM public.leagues WHERE type = 'public';
