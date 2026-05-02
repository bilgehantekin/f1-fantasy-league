-- 0016: Hatırlatma loglarını lig bazına taşı.

alter table public.notifications_log
  add column if not exists league_id uuid references public.leagues(id) on delete cascade;

drop index if exists notifications_log_user_idx;

alter table public.notifications_log
  drop constraint if exists notifications_log_user_id_race_id_kind_channel_key;

alter table public.notifications_log
  add constraint notifications_log_user_race_league_kind_channel_key
  unique(user_id, race_id, league_id, kind, channel);

create index if not exists notifications_log_user_idx
  on public.notifications_log(user_id, sent_at desc);
create index if not exists notifications_log_league_race_idx
  on public.notifications_log(league_id, race_id);
