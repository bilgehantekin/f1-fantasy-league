-- PitWall — leagues + memberships + invite_code RPC'leri

create type public.league_type as enum ('private','public');

create or replace function public.generate_invite_code()
returns text language plpgsql as $$
declare
  v_code text;
  v_chars constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_attempt int := 0;
begin
  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
    end loop;
    if not exists (select 1 from public.leagues where invite_code = v_code) then
      return v_code;
    end if;
    v_attempt := v_attempt + 1;
    if v_attempt > 50 then
      raise exception 'Could not generate unique invite code';
    end if;
  end loop;
end$$;

create table public.leagues (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  type public.league_type not null default 'private',
  owner_id uuid not null references public.profiles(id) on delete cascade,
  invite_code text unique not null check (char_length(invite_code) = 6),
  season_id smallint not null references public.seasons(id),
  created_at timestamptz not null default now()
);
create index leagues_owner_idx on public.leagues(owner_id);

create table public.league_memberships (
  league_id uuid not null references public.leagues(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  joined_at timestamptz not null default now(),
  primary key (league_id, user_id)
);
create index league_memberships_user_idx on public.league_memberships(user_id);

create or replace function public.handle_new_league()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.league_memberships (league_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict do nothing;
  return new;
end$$;
create trigger on_league_created after insert on public.leagues
  for each row execute function public.handle_new_league();

alter table public.leagues enable row level security;
alter table public.league_memberships enable row level security;

-- RLS yardımcıları: SECURITY DEFINER ile recursive policy'leri kırarız.
create or replace function public.is_member_of(p_league uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.league_memberships
    where league_id = p_league and user_id = auth.uid()
  );
$$;

create or replace function public.share_league_with(p_other uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.league_memberships m1
    join public.league_memberships m2 on m2.league_id = m1.league_id
    where m1.user_id = auth.uid() and m2.user_id = p_other
  );
$$;

grant execute on function public.is_member_of(uuid) to authenticated;
grant execute on function public.share_league_with(uuid) to authenticated;

create policy "leagues_read_member" on public.leagues for select using (
  type = 'public' or public.is_member_of(id)
);
create policy "leagues_insert_self" on public.leagues for insert with check (auth.uid() = owner_id);
create policy "leagues_owner_update" on public.leagues for update using (auth.uid() = owner_id);
create policy "leagues_owner_delete" on public.leagues for delete using (auth.uid() = owner_id);

create policy "memberships_read_in_league" on public.league_memberships for select using (
  user_id = auth.uid() or public.is_member_of(league_id)
);
create policy "memberships_insert_self" on public.league_memberships for insert with check (
  user_id = auth.uid()
);
-- Owner cannot leave their own league via direct delete
create policy "memberships_delete_self" on public.league_memberships for delete using (
  user_id = auth.uid()
  and not exists (
    select 1 from public.leagues l
    where l.id = league_memberships.league_id and l.owner_id = auth.uid()
  )
);

-- RPC: davetiye koduyla lige katıl
create or replace function public.join_league_by_code(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  select id into v_league_id from public.leagues where invite_code = upper(p_code);
  if v_league_id is null then
    raise exception 'Invalid invite code' using errcode = 'P0002';
  end if;
  insert into public.league_memberships (league_id, user_id, role)
  values (v_league_id, auth.uid(), 'member')
  on conflict (league_id, user_id) do nothing;
  return v_league_id;
end$$;

-- RPC: lig oluştur (kod otomatik üretir)
create or replace function public.create_league(p_name text, p_season_id smallint, p_type public.league_type default 'private')
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_league_id uuid;
  v_code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  v_code := public.generate_invite_code();
  insert into public.leagues (name, type, owner_id, invite_code, season_id)
  values (p_name, p_type, auth.uid(), v_code, p_season_id)
  returning id into v_league_id;
  return v_league_id;
end$$;
