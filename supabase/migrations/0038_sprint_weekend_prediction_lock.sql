-- 0038: Sprint hafta sonlarında ana yarış tahminlerini de Sprint Sıralama
-- öncesinde kilitle.
--
-- Kural:
-- - Sprint varsa tüm tahminler sprint_qualifying_at - 1 saat'te kapanır.
-- - Sprint yoksa tahminler qualifying_at - 1 saat'te kapanır.

create or replace function public.set_race_lock_at()
returns trigger language plpgsql as $$
begin
  if coalesce(new.has_sprint, false) and new.sprint_qualifying_at is not null then
    new.lock_at := new.sprint_qualifying_at - interval '1 hour';
  else
    new.lock_at := new.qualifying_at - interval '1 hour';
  end if;
  return new;
end$$;

drop trigger if exists races_set_lock_at on public.races;
create trigger races_set_lock_at
  before insert or update of qualifying_at, has_sprint, sprint_qualifying_at on public.races
  for each row execute function public.set_race_lock_at();

update public.races
set lock_at = case
  when has_sprint and sprint_qualifying_at is not null
    then sprint_qualifying_at - interval '1 hour'
  else qualifying_at - interval '1 hour'
end;
