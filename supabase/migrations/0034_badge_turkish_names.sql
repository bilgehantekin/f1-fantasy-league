-- 0034: Kalan İngilizce rozet adlarını Türkçeleştir.

begin;

update public.badges
set
  name = 'Podyum Tam İsabet',
  description = 'Podyum sıralamasını tam doğru bil'
where code = 'bullseye_podium';

update public.badges
set
  name = 'Sprint Podyum Tam İsabet',
  description = 'Bir sprintte podyum sıralamasını tam doğru bil'
where code = 'sprint_bullseye_podium';

commit;
