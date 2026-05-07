-- 0040: Kullanıcı adı üst sınırını 16 karaktere indir.
-- Karakter tipi kısıtı yok; yalnızca okunabilir kısa bir uzunluk aralığı var.

create or replace function public.complete_onboarding(p_username text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_username text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  v_username := nullif(trim(coalesce(p_username, '')), '');
  if v_username is not null then
    if char_length(v_username) < 3 or char_length(v_username) > 16 then
      raise exception 'Username must be between 3 and 16 characters';
    end if;
    update public.profiles
    set username = v_username,
        onboarding_completed = true
    where id = auth.uid();
  else
    update public.profiles
    set onboarding_completed = true
    where id = auth.uid();
  end if;
end$$;

alter table public.profiles
  drop constraint if exists profiles_username_check;

alter table public.profiles
  add constraint profiles_username_check
  check (char_length(username) between 3 and 16);
