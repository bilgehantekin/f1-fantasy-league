-- 0013: tam yarış klasmanı (22 sürücü) + iptal edilmiş yarış desteği

-- 1) race_status enum'una 'cancelled' ekle.
--    Not: Bu değer aynı migration içinde kullanılamaz (Postgres kuralı);
--    iptal işaretleme set_race_cancelled() RPC'si üzerinden yapılır.
alter type public.race_status add value if not exists 'cancelled';

-- 2) Yarış iptal açıklaması
alter table public.races
  add column if not exists cancellation_note text;

-- 3) Tam yarış klasmanı (her sürücü için satır)
create table if not exists public.race_classifications (
  race_id uuid not null references public.races(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete cascade,
  position smallint,
  status text not null default 'finished'
    check (status in ('finished','dnf','dns','dsq')),
  updated_at timestamptz not null default now(),
  primary key (race_id, driver_id)
);
create index if not exists race_classifications_race_pos_idx
  on public.race_classifications(race_id, position nulls last);

alter table public.race_classifications enable row level security;
create policy "classifications_read_all" on public.race_classifications
  for select using (true);
-- Yazma sadece service_role (ingest-openf1 edge function) üzerinden.

-- 4) Admin'in yarışı iptal edip not düşmesi için RPC
create or replace function public.set_race_cancelled(
  p_race_id uuid,
  p_note text
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not coalesce((select is_admin from public.profiles where id = auth.uid()), false) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;
  update public.races
  set status = 'cancelled'::public.race_status,
      cancellation_note = nullif(trim(p_note), '')
  where id = p_race_id;
end$$;

grant execute on function public.set_race_cancelled(uuid, text) to authenticated;
