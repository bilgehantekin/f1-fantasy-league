update public.races
set status = 'finished'
where season_id = 2026
  and status not in ('finished', 'cancelled')
  and race_at + interval '4 hours' <= now();

update public.races
set sprint_status = 'finished'
where season_id = 2026
  and has_sprint = true
  and sprint_race_at is not null
  and sprint_status not in ('finished', 'cancelled')
  and sprint_race_at + interval '2 hours' <= now();
