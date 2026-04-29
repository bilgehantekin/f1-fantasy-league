-- PitWall — canlı yarış pozisyon tablosu (Realtime publication ile)

create table public.live_positions (
  race_id uuid not null references public.races(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete cascade,
  position smallint,
  gap_to_leader_ms integer,         -- ms cinsinden lider farkı (null = leader)
  last_lap_ms integer,
  in_pit boolean not null default false,
  status text not null default 'running' check (status in ('running','retired','finished')),
  updated_at timestamptz not null default now(),
  primary key (race_id, driver_id)
);
create index live_positions_race_idx on public.live_positions(race_id, position);

alter table public.live_positions enable row level security;
create policy "live_read_all" on public.live_positions for select using (true);
-- Sadece service role yazar (Edge Function üzerinden).

-- Realtime publication: client supabase.channel(...) ile değişiklikleri dinlesin
alter publication supabase_realtime add table public.live_positions;

-- Yarış statüsünü 'locked'/'live'/'finished' arasında geçirten yardımcı fonksiyon.
-- lock-predictions cron'u tarafından çağrılır.
create or replace function public.advance_race_statuses()
returns table(id uuid, prev text, next text)
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  for r in
    update public.races set status = 'locked'
    where status = 'upcoming' and lock_at <= now() and race_at > now()
    returning races.id
  loop
    id := r.id; prev := 'upcoming'; next := 'locked'; return next;
  end loop;

  for r in
    update public.races set status = 'live'
    where status = 'locked' and race_at <= now() and race_at + interval '4 hours' > now()
    returning races.id
  loop
    id := r.id; prev := 'locked'; next := 'live'; return next;
  end loop;

  for r in
    update public.races set status = 'finished'
    where status in ('live','locked','upcoming') and race_at + interval '4 hours' <= now()
    returning races.id
  loop
    id := r.id; prev := 'old'; next := 'finished'; return next;
  end loop;
end$$;
grant execute on function public.advance_race_statuses() to service_role;
