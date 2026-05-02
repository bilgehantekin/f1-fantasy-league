-- 0014: Sprint yarış desteği
-- Bir hafta sonu içinde Sprint Qualifying + Sprint Race + Main Qualifying + Main Race
-- olabilir. Sprint için ayrı tahmin/sonuç sürelerini ve tablolarını yönetir.

-- 1) races tablosuna sprint metadata
alter table public.races
  add column if not exists has_sprint boolean not null default false,
  add column if not exists sprint_qualifying_at timestamptz,
  add column if not exists sprint_race_at timestamptz,
  add column if not exists sprint_lock_at timestamptz,
  add column if not exists sprint_status public.race_status not null default 'upcoming';

-- sprint_lock_at otomatik (sprint qualifying'den 1 saat önce)
create or replace function public.set_sprint_lock_at()
returns trigger language plpgsql as $$
begin
  if new.sprint_qualifying_at is not null then
    new.sprint_lock_at := new.sprint_qualifying_at - interval '1 hour';
  else
    new.sprint_lock_at := null;
  end if;
  return new;
end$$;

drop trigger if exists races_set_sprint_lock_at on public.races;
create trigger races_set_sprint_lock_at
  before insert or update of sprint_qualifying_at on public.races
  for each row execute function public.set_sprint_lock_at();

-- Var olan satırlardaki sprint_lock_at'i doldur (sprint zamanları sonradan girilirse)
update public.races
set sprint_lock_at = sprint_qualifying_at - interval '1 hour'
where sprint_qualifying_at is not null and sprint_lock_at is null;

-- 2) Sprint tahminleri
create table if not exists public.sprint_predictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  race_id uuid not null references public.races(id) on delete cascade,
  winner_driver_id uuid references public.drivers(id),
  p1_id uuid references public.drivers(id),
  p2_id uuid references public.drivers(id),
  p3_id uuid references public.drivers(id),
  pole_driver_id uuid references public.drivers(id),
  dnf_count smallint check (dnf_count between 0 and 20),
  score integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, race_id)
);
create index if not exists sprint_predictions_race_idx
  on public.sprint_predictions(race_id);
create index if not exists sprint_predictions_user_idx
  on public.sprint_predictions(user_id);

alter table public.sprint_predictions enable row level security;

create policy "sprint_pred_owner_select" on public.sprint_predictions
  for select using (auth.uid() = user_id);
create policy "sprint_pred_owner_insert" on public.sprint_predictions
  for insert with check (auth.uid() = user_id);
create policy "sprint_pred_owner_update" on public.sprint_predictions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sprint_pred_owner_delete" on public.sprint_predictions
  for delete using (auth.uid() = user_id);

-- Lig içi okuma: aynı ligde olanlar birbirinin sprint tahminini görebilir
create policy "sprint_pred_league_select" on public.sprint_predictions
  for select using (
    exists (
      select 1
      from public.league_memberships m1
      join public.league_memberships m2 on m1.league_id = m2.league_id
      where m1.user_id = sprint_predictions.user_id
        and m2.user_id = auth.uid()
    )
  );

-- updated_at güncelle
create or replace function public.touch_sprint_pred_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end$$;

drop trigger if exists sprint_pred_touch on public.sprint_predictions;
create trigger sprint_pred_touch
  before update on public.sprint_predictions
  for each row execute function public.touch_sprint_pred_updated_at();

-- Lock invariant: sprint_lock_at sonrası yazılamaz
create or replace function public.assert_sprint_pred_unlocked()
returns trigger language plpgsql as $$
declare
  v_lock_at timestamptz;
  v_has_sprint boolean;
begin
  select sprint_lock_at, has_sprint
    into v_lock_at, v_has_sprint
    from public.races where id = new.race_id;
  if not coalesce(v_has_sprint, false) then
    raise exception 'No sprint for this race' using errcode = '22023';
  end if;
  if v_lock_at is null then
    raise exception 'Sprint lock_at missing' using errcode = '22023';
  end if;
  if now() >= v_lock_at then
    raise exception 'Sprint predictions are locked' using errcode = '23514';
  end if;
  return new;
end$$;

drop trigger if exists sprint_pred_lock on public.sprint_predictions;
create trigger sprint_pred_lock
  before insert or update on public.sprint_predictions
  for each row execute function public.assert_sprint_pred_unlocked();

-- 3) Sprint sonuçları
create table if not exists public.sprint_results (
  race_id uuid primary key references public.races(id) on delete cascade,
  p1 uuid not null references public.drivers(id),
  p2 uuid not null references public.drivers(id),
  p3 uuid not null references public.drivers(id),
  pole uuid not null references public.drivers(id),
  dnf_count smallint not null check (dnf_count between 0 and 20),
  finalized_at timestamptz not null default now()
);
alter table public.sprint_results enable row level security;
create policy "sprint_results_read_all" on public.sprint_results
  for select using (true);
-- Yazma sadece service_role.

-- 4) Sprint klasmanı (tüm sürücüler)
create table if not exists public.sprint_classifications (
  race_id uuid not null references public.races(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete cascade,
  position smallint,
  status text not null default 'finished'
    check (status in ('finished','dnf','dns','dsq')),
  updated_at timestamptz not null default now(),
  primary key (race_id, driver_id)
);
create index if not exists sprint_classifications_race_pos_idx
  on public.sprint_classifications(race_id, position nulls last);
alter table public.sprint_classifications enable row level security;
create policy "sprint_classifications_read_all" on public.sprint_classifications
  for select using (true);

-- 5) Sprint puan formülü (ana yarıştan biraz daha düşük katsayılar)
create or replace function public.compute_sprint_score(
  p_pred public.sprint_predictions,
  p_res public.sprint_results
) returns integer language plpgsql immutable as $$
declare
  v_score integer := 0;
  v_podium_set uuid[];
  v_pred_podium uuid[];
begin
  if p_pred.winner_driver_id is not null and p_pred.winner_driver_id = p_res.p1 then
    v_score := v_score + 8;
  end if;

  if p_pred.p1_id = p_res.p1 and p_pred.p2_id = p_res.p2 and p_pred.p3_id = p_res.p3 then
    v_score := v_score + 12;
  end if;

  v_podium_set := array[p_res.p1, p_res.p2, p_res.p3];
  v_pred_podium := array[p_pred.p1_id, p_pred.p2_id, p_pred.p3_id];
  for i in 1..3 loop
    if v_pred_podium[i] is not null and v_pred_podium[i] = any(v_podium_set) then
      v_score := v_score + 4;
    end if;
  end loop;

  if p_pred.pole_driver_id is not null and p_pred.pole_driver_id = p_res.pole then
    v_score := v_score + 6;
  end if;

  if p_pred.dnf_count is not null then
    if p_pred.dnf_count = p_res.dnf_count then
      v_score := v_score + 4;
    elsif abs(p_pred.dnf_count - p_res.dnf_count) = 1 then
      v_score := v_score + 2;
    end if;
  end if;

  return v_score;
end$$;

create or replace function public.score_sprint(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.sprint_results;
  v_pred public.sprint_predictions;
  v_count int := 0;
begin
  select * into v_res from public.sprint_results where race_id = p_race_id;
  if not found then return 0; end if;

  for v_pred in select * from public.sprint_predictions where race_id = p_race_id loop
    update public.sprint_predictions
    set score = public.compute_sprint_score(v_pred, v_res)
    where id = v_pred.id;
    v_count := v_count + 1;
  end loop;

  update public.races set sprint_status = 'finished' where id = p_race_id;
  return v_count;
end$$;

create or replace function public.handle_sprint_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.score_sprint(new.race_id);
  return new;
end$$;

drop trigger if exists sprint_results_score on public.sprint_results;
create trigger sprint_results_score
  after insert or update on public.sprint_results
  for each row execute function public.handle_sprint_result();

-- 6) Sprint için status ilerletme
create or replace function public.advance_sprint_statuses()
returns table(id uuid, prev text, next text)
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  for r in
    update public.races set sprint_status = 'locked'
    where has_sprint
      and sprint_status = 'upcoming'
      and sprint_lock_at is not null
      and sprint_lock_at <= now()
      and sprint_race_at > now()
    returning races.id
  loop
    id := r.id; prev := 'upcoming'; next := 'locked'; return next;
  end loop;

  for r in
    update public.races set sprint_status = 'live'
    where has_sprint
      and sprint_status = 'locked'
      and sprint_race_at <= now()
      and sprint_race_at + interval '2 hours' > now()
    returning races.id
  loop
    id := r.id; prev := 'locked'; next := 'live'; return next;
  end loop;

  for r in
    update public.races set sprint_status = 'finished'
    where has_sprint
      and sprint_status in ('live','locked','upcoming')
      and sprint_race_at + interval '2 hours' <= now()
    returning races.id
  loop
    id := r.id; prev := 'old'; next := 'finished'; return next;
  end loop;
end$$;
grant execute on function public.advance_sprint_statuses() to service_role;

-- 7) İptal yarış için sprint_status'u da güncelleyen RPC genişletmesi
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
      sprint_status = case when has_sprint then 'cancelled'::public.race_status else sprint_status end,
      cancellation_note = nullif(trim(p_note), '')
  where id = p_race_id;
end$$;

grant execute on function public.set_race_cancelled(uuid, text) to authenticated;
