-- 0049: Premium league limit (free=2 / premium=10) sürekli açık olsun.
-- Önceki versiyon `current_setting('app.enable_premium_league_limits')`
-- üzerinden okuyordu ve Supabase managed ortamda bu parametre normal
-- kullanıcılar tarafından set edilemiyor; o yüzden bayrağı doğrudan
-- function gövdesinde sabitliyoruz.

create or replace function public.premium_league_limits_enabled()
returns boolean
language sql immutable security definer set search_path = public as $$
  select true;
$$;

grant execute on function public.premium_league_limits_enabled() to authenticated;
