-- 0035: Ana yarış/sprint rozet çiftlerinin adlarını tutarlı hale getir.

begin;

insert into public.badges (code, name, description, icon, rarity)
values
  (
    'sprint_pole_caller',
    'Sprint Pole Avcısı',
    'Bir sprintte pole pozisyonunu doğru bil',
    '🏁',
    'common'
  )
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  icon = excluded.icon,
  rarity = excluded.rarity;

update public.badges
set name = 'Podyum Tam İsabet'
where code = 'bullseye_podium';

update public.badges
set name = 'Sprint Podyum Tam İsabet'
where code = 'sprint_bullseye_podium';

update public.badges
set name = 'Pole Avcısı'
where code = 'pole_caller';

update public.badges
set name = 'Sprint Pole Avcısı'
where code = 'sprint_pole_caller';

commit;
