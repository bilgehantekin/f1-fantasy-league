-- PitWall — public lig (otomatik üyelik) + rozet sistemi

-- Public ligler sahipsiz olabilsin: owner_id nullable + delete'te SET NULL
alter table public.leagues alter column owner_id drop not null;
alter table public.leagues drop constraint leagues_owner_id_fkey;
alter table public.leagues add constraint leagues_owner_id_fkey
  foreign key (owner_id) references public.profiles(id) on delete set null;

-- 1) Sezon başına bir public lig oluştur
create or replace function public.ensure_public_league(p_season_id smallint, p_owner uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
begin
  select id into v_league_id from public.leagues
    where type = 'public' and season_id = p_season_id limit 1;
  if v_league_id is null then
    insert into public.leagues (name, type, owner_id, invite_code, season_id)
    values (
      'Genel Lig ' || p_season_id::text,
      'public',
      p_owner,
      'PB' || lpad((floor(random() * 10000))::int::text, 4, '0'),
      p_season_id
    )
    returning id into v_league_id;
  end if;
  return v_league_id;
end$$;

-- 2) Yeni kullanıcı eklendiğinde aktif sezonun public ligine ekle
create or replace function public.add_to_public_leagues()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
  v_season_id smallint;
begin
  -- Aktif sezon
  select id into v_season_id from public.seasons where is_active = true order by id desc limit 1;
  if v_season_id is null then return new; end if;

  v_league_id := public.ensure_public_league(v_season_id, new.id);
  insert into public.league_memberships (league_id, user_id, role)
  values (v_league_id, new.id, 'member')
  on conflict do nothing;
  return new;
end$$;
create trigger on_profile_created_public
  after insert on public.profiles
  for each row execute function public.add_to_public_leagues();

-- Mevcut profilleri retroaktif ekle
do $$
declare
  v_season_id smallint;
  v_league_id uuid;
  v_profile record;
begin
  select id into v_season_id from public.seasons where is_active = true order by id desc limit 1;
  if v_season_id is null then return; end if;
  v_league_id := public.ensure_public_league(v_season_id);
  for v_profile in select id from public.profiles loop
    insert into public.league_memberships (league_id, user_id, role)
    values (v_league_id, v_profile.id, 'member')
    on conflict do nothing;
  end loop;
end$$;

-- 3) Rozetler
create table public.badges (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text not null,
  icon text not null,                  -- emoji veya material icon adı
  rarity text not null default 'common' check (rarity in ('common','rare','epic','legendary')),
  created_at timestamptz not null default now()
);
alter table public.badges enable row level security;
create policy "badges_read_all" on public.badges for select using (true);

create table public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  race_id uuid references public.races(id) on delete cascade,
  awarded_at timestamptz not null default now(),
  unique(user_id, badge_id, race_id)
);
create index user_badges_user_idx on public.user_badges(user_id, awarded_at desc);

alter table public.user_badges enable row level security;
create policy "user_badges_read_all" on public.user_badges for select using (true);
-- Sadece service role yazar

-- 4) Başlangıç rozet seti
insert into public.badges (code, name, description, icon, rarity) values
  ('perfect_week',     'Mükemmel Hafta',  'Bir yarışın 6 sorusunu da doğru bil',          '⭐', 'legendary'),
  ('bullseye_podium',  'Bullseye Podium', 'Podium sıralamasını tam doğru bil',             '🎯', 'epic'),
  ('joker_master',     'Joker Üstadı',    'Joker sorusunu doğru bil',                      '🃏', 'common'),
  ('dnf_oracle',       'DNF Kahini',      'DNF sayısını tam bil',                          '🔮', 'rare'),
  ('pole_caller',      'Pole Avcısı',     'Pole pozisyonunu doğru bil',                    '🏁', 'common'),
  ('fastest_caller',   'Hız Şeytanı',     'En hızlı turu doğru bil',                       '⚡', 'common'),
  ('weekly_winner',    'Hafta Şampiyonu', 'Bir ligde haftanın 1.-si ol',             '🏆', 'epic'),
  ('three_in_row',     'Üçlü Seri',       'Üst üste 3 yarışta podium tahmini doğru',       '🔥', 'rare')
on conflict (code) do nothing;
