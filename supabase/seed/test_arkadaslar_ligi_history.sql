-- Test data: Arkadaşlar Ligi geçmiş yarış senaryoları.
--
-- Amaç:
-- - Mevcut tüm profilleri RS38SVPJ kodlu Arkadaşlar Ligi'ne ekler.
-- - Australian, Chinese, Japanese ve Miami GP için geçmiş tahmin verisi üretir.
-- - Chinese ve Miami GP için sprint tahminleri de üretir.
-- - Sonuç satırları zaten varsa gerçek sonuçları ezmez; eksikse makul fallback ekler.
-- - Mevcut tahmin satırlarını ezmez; çakışmada DO NOTHING kullanır.
-- - Skorları ve rozetleri yeniden hesaplar.
--
-- Çalıştırma:
--   supabase db reset --local --seed supabase/seed/test_arkadaslar_ligi_history.sql
-- veya SQL editor/psql içinde servis/admin yetkisiyle çalıştır.

begin;

insert into public.seasons (id, is_active)
values (2026, true)
on conflict (id) do update set is_active = excluded.is_active;

insert into public.teams (season_id, code, name, color)
values
  (2026, 'RBR', 'Red Bull Racing', '#3671C6'),
  (2026, 'MCL', 'McLaren', '#FF8000'),
  (2026, 'FER', 'Ferrari', '#E80020'),
  (2026, 'MER', 'Mercedes', '#27F4D2'),
  (2026, 'AST', 'Aston Martin', '#229971'),
  (2026, 'WIL', 'Williams', '#64C4FF')
on conflict (season_id, code) do update
set name = excluded.name,
    color = excluded.color;

with team_ids as (
  select code, id from public.teams where season_id = 2026
)
insert into public.drivers (season_id, code, full_name, number, team_id)
values
  (2026, 'VER', 'Max Verstappen', 1, (select id from team_ids where code = 'RBR')),
  (2026, 'ANT', 'Kimi Antonelli', 12, (select id from team_ids where code = 'MER')),
  (2026, 'NOR', 'Lando Norris', 4, (select id from team_ids where code = 'MCL')),
  (2026, 'PIA', 'Oscar Piastri', 81, (select id from team_ids where code = 'MCL')),
  (2026, 'LEC', 'Charles Leclerc', 16, (select id from team_ids where code = 'FER')),
  (2026, 'HAM', 'Lewis Hamilton', 44, (select id from team_ids where code = 'FER')),
  (2026, 'RUS', 'George Russell', 63, (select id from team_ids where code = 'MER')),
  (2026, 'ALO', 'Fernando Alonso', 14, (select id from team_ids where code = 'AST')),
  (2026, 'SAI', 'Carlos Sainz', 55, (select id from team_ids where code = 'WIL'))
on conflict (season_id, code) do update
set full_name = excluded.full_name,
    number = excluded.number,
    team_id = excluded.team_id;

	insert into public.races (
  season_id,
  round,
  name,
  circuit,
  qualifying_at,
  race_at,
  status,
  has_sprint,
  sprint_qualifying_at,
  sprint_race_at,
  sprint_status
)
values
  (
    2026,
    1,
    'Australian Grand Prix',
    'Albert Park Circuit',
    '2026-03-07 06:00:00+00',
    '2026-03-08 05:00:00+00',
    'finished',
    false,
    null,
    null,
    'upcoming'
  ),
  (
    2026,
    2,
    'Chinese Grand Prix',
    'Shanghai International Circuit',
    '2026-03-14 07:00:00+00',
    '2026-03-15 07:00:00+00',
    'finished',
    true,
    '2026-03-13 07:00:00+00',
    '2026-03-14 03:00:00+00',
    'finished'
  ),
  (
    2026,
    3,
    'Japanese Grand Prix',
    'Suzuka Circuit',
    '2026-03-28 06:00:00+00',
    '2026-03-29 05:00:00+00',
    'finished',
    false,
    null,
    null,
    'upcoming'
  ),
  (
    2026,
    4,
    'Miami Grand Prix',
    'Miami International Autodrome',
    '2026-05-02 20:00:00+00',
    '2026-05-03 20:00:00+00',
    'finished',
    true,
    '2026-05-01 20:30:00+00',
    '2026-05-02 16:00:00+00',
    'finished'
  )
on conflict (season_id, round) do update
set name = excluded.name,
    circuit = excluded.circuit,
    qualifying_at = excluded.qualifying_at,
    race_at = excluded.race_at,
    status = excluded.status,
    has_sprint = excluded.has_sprint,
    sprint_qualifying_at = excluded.sprint_qualifying_at,
    sprint_race_at = excluded.sprint_race_at,
    sprint_status = case
      when excluded.has_sprint then excluded.sprint_status
      else public.races.sprint_status
	    end;

insert into public.races (
  season_id,
  round,
  name,
  circuit,
  qualifying_at,
  race_at,
  status,
  has_sprint,
  sprint_qualifying_at,
  sprint_race_at,
  sprint_status
)
values
  (2026, 5, 'Canadian Grand Prix', 'Circuit Gilles-Villeneuve', '2026-05-23 20:00:00+00', '2026-05-24 18:00:00+00', 'upcoming', true, '2026-05-22 20:00:00+00', '2026-05-23 16:00:00+00', 'upcoming'),
  (2026, 6, 'Monaco Grand Prix', 'Circuit de Monaco', '2026-06-06 14:00:00+00', '2026-06-07 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 7, 'Barcelona-Catalunya Grand Prix', 'Circuit de Barcelona-Catalunya', '2026-06-13 14:00:00+00', '2026-06-14 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 8, 'Austrian Grand Prix', 'Red Bull Ring', '2026-06-27 14:00:00+00', '2026-06-28 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 9, 'British Grand Prix', 'Silverstone Circuit', '2026-07-04 14:00:00+00', '2026-07-05 14:00:00+00', 'upcoming', true, '2026-07-03 14:00:00+00', '2026-07-04 10:00:00+00', 'upcoming'),
  (2026, 10, 'Belgian Grand Prix', 'Circuit de Spa-Francorchamps', '2026-07-18 14:00:00+00', '2026-07-19 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 11, 'Hungarian Grand Prix', 'Hungaroring', '2026-07-25 14:00:00+00', '2026-07-26 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 12, 'Dutch Grand Prix', 'Circuit Zandvoort', '2026-08-22 14:00:00+00', '2026-08-23 13:00:00+00', 'upcoming', true, '2026-08-21 14:00:00+00', '2026-08-22 10:00:00+00', 'upcoming'),
  (2026, 13, 'Italian Grand Prix', 'Autodromo Nazionale Monza', '2026-09-05 14:00:00+00', '2026-09-06 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 14, 'Spanish Grand Prix', 'Madring', '2026-09-12 14:00:00+00', '2026-09-13 13:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 15, 'Azerbaijan Grand Prix', 'Baku City Circuit', '2026-09-25 13:00:00+00', '2026-09-26 11:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 16, 'Singapore Grand Prix', 'Marina Bay Street Circuit', '2026-10-10 13:00:00+00', '2026-10-11 12:00:00+00', 'upcoming', true, '2026-10-09 13:00:00+00', '2026-10-10 09:00:00+00', 'upcoming'),
  (2026, 17, 'United States Grand Prix', 'Circuit of The Americas', '2026-10-24 21:00:00+00', '2026-10-25 20:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 18, 'Mexico City Grand Prix', 'Autodromo Hermanos Rodriguez', '2026-10-31 21:00:00+00', '2026-11-01 20:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 19, 'São Paulo Grand Prix', 'Autodromo Jose Carlos Pace', '2026-11-07 18:00:00+00', '2026-11-08 17:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 20, 'Las Vegas Grand Prix', 'Las Vegas Strip Circuit', '2026-11-21 06:00:00+00', '2026-11-22 06:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 21, 'Qatar Grand Prix', 'Lusail International Circuit', '2026-11-28 17:00:00+00', '2026-11-29 16:00:00+00', 'upcoming', false, null, null, 'upcoming'),
  (2026, 22, 'Abu Dhabi Grand Prix', 'Yas Marina Circuit', '2026-12-05 14:00:00+00', '2026-12-06 13:00:00+00', 'upcoming', false, null, null, 'upcoming')
on conflict (season_id, round) do update
set name = excluded.name,
    circuit = excluded.circuit,
    qualifying_at = excluded.qualifying_at,
    race_at = excluded.race_at,
    status = case
      when public.races.status = 'finished' then public.races.status
      else excluded.status
    end,
    has_sprint = excluded.has_sprint,
    sprint_qualifying_at = excluded.sprint_qualifying_at,
    sprint_race_at = excluded.sprint_race_at,
    sprint_status = case
      when public.races.sprint_status = 'finished' then public.races.sprint_status
      else excluded.sprint_status
    end;

insert into public.joker_questions (race_id, text, options, correct_option, points)
select r.id,
       'Yarışta güvenlik aracı çıkar mı?',
       '["Evet","Hayır"]'::jsonb,
       case r.name
         when 'Australian Grand Prix' then 'Hayır'
         when 'Chinese Grand Prix' then 'Hayır'
         when 'Japanese Grand Prix' then 'Hayır'
         else 'Evet'
       end,
       12
from public.races r
where r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  )
on conflict (race_id) do update
set text = excluded.text,
    options = excluded.options,
    correct_option = excluded.correct_option,
    points = excluded.points;

do $$
declare
  v_owner uuid;
  v_league uuid;
begin
  select id into v_owner
  from public.profiles
  order by case when lower(username) like 'bilge%' then 0 else 1 end,
           lower(username),
           id
  limit 1;

  if v_owner is null then
    raise exception 'Profil bulunamadı. Önce en az bir auth user/profile oluştur.';
  end if;

  select id into v_league
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1;

  if v_league is null then
    select id into v_league
    from public.leagues
    where season_id = 2026 and name = 'Arkadaşlar Ligi'
    order by created_at
    limit 1;
  end if;

  if v_league is null then
    insert into public.leagues (name, type, owner_id, invite_code, season_id)
    values ('Arkadaşlar Ligi', 'private', v_owner, 'RS38SVPJ', 2026)
    returning id into v_league;
  elsif not exists (
    select 1
    from public.leagues other
    where other.invite_code = 'RS38SVPJ'
      and other.id <> v_league
  ) then
    update public.leagues
    set name = 'Arkadaşlar Ligi',
        season_id = 2026,
        invite_code = 'RS38SVPJ'
    where id = v_league;
  end if;
end$$;

with league as (
  select id, owner_id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
)
insert into public.league_memberships (league_id, user_id, role, joined_at)
select l.id,
       p.id,
       case when p.id = l.owner_id then 'owner' else 'member' end,
       now() - ((row_number() over (order by lower(p.username), p.id))::text || ' days')::interval
from league l
cross join public.profiles p
on conflict (league_id, user_id) do update
set role = case
  when excluded.role = 'owner' then 'owner'
  else public.league_memberships.role
end;

alter table public.predictions disable trigger predictions_enforce_lock;
alter table public.sprint_predictions disable trigger sprint_pred_lock;

with league as (
  select id from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
),
members as (
  select p.id as user_id,
         p.username,
         row_number() over (order by lower(p.username), p.id) as rn,
         count(*) over () as total_members
  from public.profiles p
  join public.league_memberships lm on lm.user_id = p.id
  join league l on l.id = lm.league_id
),
drivers as (
  select
    (max(id::text) filter (where code = 'VER'))::uuid as ver,
    (max(id::text) filter (where code = 'ANT'))::uuid as ant,
    (max(id::text) filter (where code = 'NOR'))::uuid as nor,
    (max(id::text) filter (where code = 'PIA'))::uuid as pia,
    (max(id::text) filter (where code = 'LEC'))::uuid as lec,
    (max(id::text) filter (where code = 'HAM'))::uuid as ham,
    (max(id::text) filter (where code = 'RUS'))::uuid as rus
  from public.drivers
  where season_id = 2026
),
teams as (
  select
    (max(id::text) filter (where code = 'RBR'))::uuid as rbr,
    (max(id::text) filter (where code = 'MCL'))::uuid as mcl,
    (max(id::text) filter (where code = 'FER'))::uuid as fer,
    (max(id::text) filter (where code = 'MER'))::uuid as mer
  from public.teams
  where season_id = 2026
),
race_plan as (
  select r.id as race_id,
         r.name,
         case r.name
           when 'Australian Grand Prix' then 1
           when 'Chinese Grand Prix' then 2
           when 'Japanese Grand Prix' then 3
           else 4
         end as race_idx,
         case r.name
           when 'Australian Grand Prix' then d.rus
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.ant
         end as p1,
         case r.name
           when 'Australian Grand Prix' then d.ant
           when 'Chinese Grand Prix' then d.rus
           when 'Japanese Grand Prix' then d.pia
           else d.nor
         end as p2,
         case r.name
           when 'Australian Grand Prix' then d.lec
           when 'Chinese Grand Prix' then d.ham
           when 'Japanese Grand Prix' then d.lec
           else d.pia
         end as p3,
         case r.name
           when 'Australian Grand Prix' then d.rus
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.ant
         end as pole,
         case r.name
           when 'Australian Grand Prix' then d.ver
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.nor
         end as fastest_lap,
         case r.name
           when 'Chinese Grand Prix' then t.mer
           when 'Japanese Grand Prix' then t.mer
           when 'Miami Grand Prix' then t.mer
           else t.mer
         end as top_team,
         case r.name
           when 'Australian Grand Prix' then 3
           when 'Chinese Grand Prix' then 3
           when 'Japanese Grand Prix' then 2
           else 4
         end as dnf_count,
         case r.name
           when 'Australian Grand Prix' then false
           when 'Chinese Grand Prix' then false
           when 'Japanese Grand Prix' then false
           else true
         end as safety_car,
         case r.name
           when 'Australian Grand Prix' then 'Hayır'
           when 'Chinese Grand Prix' then 'Hayır'
           when 'Japanese Grand Prix' then 'Hayır'
           else 'Evet'
         end as joker_correct,
         d.ver, d.ant, d.nor, d.pia, d.lec, d.ham, d.rus,
         t.rbr, t.mcl, t.fer, t.mer
  from public.races r
  cross join drivers d
  cross join teams t
  where r.season_id = 2026
    and r.name in (
      'Australian Grand Prix',
      'Chinese Grand Prix',
      'Japanese Grand Prix',
      'Miami Grand Prix'
    )
),
seed_rows as (
  select l.id as league_id,
         m.*,
         rp.*,
         ((rp.race_idx - 1) % greatest(m.total_members, 1)) + 1 as target_rn,
         (m.rn + rp.race_idx) % 5 as variant
  from league l
  cross join members m
  join race_plan rp on true
  where (
      m.rn = (((rp.race_idx - 1) % greatest(m.total_members, 1)) + 1)
      or (m.rn + rp.race_idx) % 5 <> 0
    )
    and not (rp.name = 'Australian Grand Prix' and lower(m.username) = 'bilge')
)
insert into public.predictions (
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  top_team_id,
  pole_driver_id,
  fastest_lap_driver_id,
  dnf_count,
  safety_car,
  joker_option,
  locked_at
)
select user_id,
       race_id,
       league_id,
       case when rn = target_rn then p1
            when variant = 0 then p2
            when variant = 1 then p1
            when variant = 2 then p3
            when variant = 3 then lec
            else ham end,
       case when rn = target_rn then p1
            when variant = 0 then p2
            when variant = 1 then p1
            when variant = 2 then lec
            when variant = 3 then rus
            else pia end,
       case when rn = target_rn then p2
            when variant = 0 then p1
            when variant = 1 then p3
            when variant = 2 then p1
            when variant = 3 then nor
            else lec end,
       case when rn = target_rn then p3
            when variant = 0 then p3
            when variant = 1 then p2
            when variant = 2 then ham
            when variant = 3 then ver
            else ham end,
       case when rn = target_rn or variant in (1, 4) then top_team
            when variant = 2 then fer
            when variant = 3 then mer
            else rbr end,
       case when rn = target_rn or variant = 1 then pole
            when variant = 2 then lec
            when variant = 3 then rus
            else ver end,
       case when rn = target_rn or variant = 4 then fastest_lap
            when variant = 2 then ham
            else nor end,
       case when rn = target_rn or variant in (0, 3) then dnf_count
            when variant = 1 then greatest(dnf_count - 1, 0)
            else least(dnf_count + 1, 22) end,
       case when rn = target_rn or variant in (1, 3) then safety_car else not safety_car end,
       case when rn = target_rn or variant in (0, 2) then joker_correct
            when joker_correct = 'Evet' then 'Hayır'
            else 'Evet' end,
       now()
from seed_rows
on conflict (user_id, race_id, league_id) do nothing;

with drivers as (
  select
    (max(id::text) filter (where code = 'VER'))::uuid as ver,
    (max(id::text) filter (where code = 'ANT'))::uuid as ant,
    (max(id::text) filter (where code = 'NOR'))::uuid as nor,
    (max(id::text) filter (where code = 'PIA'))::uuid as pia,
    (max(id::text) filter (where code = 'LEC'))::uuid as lec,
    (max(id::text) filter (where code = 'HAM'))::uuid as ham,
    (max(id::text) filter (where code = 'RUS'))::uuid as rus
  from public.drivers
  where season_id = 2026
),
teams as (
  select
    (max(id::text) filter (where code = 'RBR'))::uuid as rbr,
    (max(id::text) filter (where code = 'MCL'))::uuid as mcl,
    (max(id::text) filter (where code = 'FER'))::uuid as fer,
    (max(id::text) filter (where code = 'MER'))::uuid as mer
  from public.teams
  where season_id = 2026
),
results as (
  select r.id as race_id,
         r.name,
         case r.name
           when 'Australian Grand Prix' then d.rus
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.ant
         end as p1,
         case r.name
           when 'Australian Grand Prix' then d.ant
           when 'Chinese Grand Prix' then d.rus
           when 'Japanese Grand Prix' then d.pia
           else d.nor
         end as p2,
         case r.name
           when 'Australian Grand Prix' then d.lec
           when 'Chinese Grand Prix' then d.ham
           when 'Japanese Grand Prix' then d.lec
           else d.pia
         end as p3,
         case r.name
           when 'Australian Grand Prix' then d.rus
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.ant
         end as pole,
         case r.name
           when 'Australian Grand Prix' then d.ver
           when 'Chinese Grand Prix' then d.ant
           when 'Japanese Grand Prix' then d.ant
           else d.nor
         end as fastest_lap,
         t.mer as top_team,
         case r.name
           when 'Australian Grand Prix' then 3
           when 'Chinese Grand Prix' then 3
           when 'Japanese Grand Prix' then 2
           else 4
         end as dnf_count,
         case r.name
           when 'Australian Grand Prix' then false
           when 'Chinese Grand Prix' then false
           when 'Japanese Grand Prix' then false
           else true
         end as safety_car,
         case r.name
           when 'Australian Grand Prix' then 'Hayır'
           when 'Chinese Grand Prix' then 'Hayır'
           when 'Japanese Grand Prix' then 'Hayır'
           else 'Evet'
         end as joker_correct
  from public.races r
  cross join drivers d
  cross join teams t
  where r.season_id = 2026
    and r.name in (
      'Australian Grand Prix',
      'Chinese Grand Prix',
      'Japanese Grand Prix',
      'Miami Grand Prix'
    )
)
insert into public.race_results (
  race_id,
  p1,
  p2,
  p3,
  pole,
  fastest_lap,
  top_team_id,
  dnf_count,
  safety_car,
  joker_correct,
  finalized_at
)
select race_id,
       p1,
       p2,
       p3,
       pole,
       fastest_lap,
       top_team,
       dnf_count,
       safety_car,
       joker_correct,
       now()
from results
on conflict (race_id) do nothing;

with league as (
  select id from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
),
members as (
  select p.id as user_id,
         row_number() over (order by lower(p.username), p.id) as rn,
         count(*) over () as total_members
  from public.profiles p
  join public.league_memberships lm on lm.user_id = p.id
  join league l on l.id = lm.league_id
),
drivers as (
  select
    (max(id::text) filter (where code = 'VER'))::uuid as ver,
    (max(id::text) filter (where code = 'NOR'))::uuid as nor,
    (max(id::text) filter (where code = 'PIA'))::uuid as pia,
    (max(id::text) filter (where code = 'LEC'))::uuid as lec,
    (max(id::text) filter (where code = 'HAM'))::uuid as ham,
    (max(id::text) filter (where code = 'RUS'))::uuid as rus
  from public.drivers
  where season_id = 2026
),
teams as (
  select
    (max(id::text) filter (where code = 'RBR'))::uuid as rbr,
    (max(id::text) filter (where code = 'MCL'))::uuid as mcl,
    (max(id::text) filter (where code = 'FER'))::uuid as fer,
    (max(id::text) filter (where code = 'MER'))::uuid as mer
  from public.teams
  where season_id = 2026
),
	sprint_plan as (
	  select r.id as race_id,
	         r.name,
	         case r.name when 'Chinese Grand Prix' then 2 else 4 end as race_idx,
	         case r.name when 'Chinese Grand Prix' then d.rus else d.nor end as p1,
	         case r.name when 'Chinese Grand Prix' then d.lec else d.pia end as p2,
	         case r.name when 'Chinese Grand Prix' then d.ham else d.lec end as p3,
	         case r.name when 'Chinese Grand Prix' then d.rus else d.nor end as pole,
	         case r.name when 'Chinese Grand Prix' then t.fer else t.mcl end as top_team,
	         case r.name when 'Chinese Grand Prix' then 3 else 0 end as dnf_count,
	         false as safety_car,
	         d.ver, d.nor, d.pia, d.lec, d.ham, d.rus,
	         t.rbr, t.mcl, t.fer, t.mer
	  from public.races r
	  cross join drivers d
	  cross join teams t
	  where r.season_id = 2026
	    and r.name in ('Chinese Grand Prix', 'Miami Grand Prix')
	),
	seed_rows as (
	  select l.id as league_id,
	         m.*,
	         sp.*,
	         ((sp.race_idx - 1) % greatest(m.total_members, 1)) + 1 as target_rn,
	         (m.rn + sp.race_idx) % 5 as variant
	  from league l
	  cross join members m
	  cross join sprint_plan sp
	  where m.rn = (((sp.race_idx - 1) % greatest(m.total_members, 1)) + 1)
	     or (m.rn + sp.race_idx) % 4 <> 0
)
insert into public.sprint_predictions (
  user_id,
  race_id,
  league_id,
  winner_driver_id,
  p1_id,
  p2_id,
  p3_id,
  top_team_id,
  pole_driver_id,
  dnf_count,
  safety_car
)
select user_id,
       race_id,
       league_id,
       case when rn = target_rn then p1
            when variant = 0 then p2
            when variant = 1 then p1
            when variant = 2 then p3
            when variant = 3 then lec
            else nor end,
       case when rn = target_rn then p1
            when variant = 0 then p2
            when variant = 1 then p1
            when variant = 2 then lec
            when variant = 3 then rus
            else pia end,
       case when rn = target_rn then p2
            when variant = 0 then p1
            when variant = 1 then p3
            when variant = 2 then p1
            when variant = 3 then nor
            else lec end,
       case when rn = target_rn then p3
            when variant = 0 then p3
            when variant = 1 then p2
            when variant = 2 then ham
            when variant = 3 then ver
            else ham end,
       case when rn = target_rn or variant in (1, 4) then top_team
            when variant = 2 then mcl
            when variant = 3 then mer
            else rbr end,
       case when rn = target_rn or variant = 1 then pole
            when variant = 2 then lec
            when variant = 3 then rus
            else ver end,
       case when rn = target_rn or variant in (0, 3) then dnf_count
            when variant = 1 then greatest(dnf_count - 1, 0)
            else least(dnf_count + 1, 22) end,
       case when rn = target_rn or variant in (1, 3) then safety_car else not safety_car end
from seed_rows
on conflict (user_id, race_id, league_id) do nothing;

with drivers as (
  select
    (max(id::text) filter (where code = 'RUS'))::uuid as rus,
    (max(id::text) filter (where code = 'NOR'))::uuid as nor,
    (max(id::text) filter (where code = 'PIA'))::uuid as pia,
    (max(id::text) filter (where code = 'LEC'))::uuid as lec,
    (max(id::text) filter (where code = 'HAM'))::uuid as ham
  from public.drivers
  where season_id = 2026
),
teams as (
  select
    (max(id::text) filter (where code = 'FER'))::uuid as fer,
    (max(id::text) filter (where code = 'MCL'))::uuid as mcl
  from public.teams
  where season_id = 2026
),
	sprint_results_seed as (
	  select r.id as race_id,
	         r.name
	  from public.races r
	  where r.season_id = 2026
	    and r.name in ('Chinese Grand Prix', 'Miami Grand Prix')
	)
insert into public.sprint_results (
  race_id,
  p1,
  p2,
  p3,
  pole,
  top_team_id,
  dnf_count,
  safety_car,
  finalized_at
)
select sprint_results_seed.race_id,
       case sprint_results_seed.name when 'Chinese Grand Prix' then drivers.rus else drivers.nor end,
       case sprint_results_seed.name when 'Chinese Grand Prix' then drivers.lec else drivers.pia end,
       case sprint_results_seed.name when 'Chinese Grand Prix' then drivers.ham else drivers.lec end,
       case sprint_results_seed.name when 'Chinese Grand Prix' then drivers.rus else drivers.nor end,
       case sprint_results_seed.name when 'Chinese Grand Prix' then teams.fer else teams.mcl end,
       case sprint_results_seed.name when 'Chinese Grand Prix' then 3 else 0 end,
       false,
       now()
from sprint_results_seed
cross join drivers
cross join teams
on conflict (race_id) do nothing;

alter table public.predictions enable trigger predictions_enforce_lock;
alter table public.sprint_predictions enable trigger sprint_pred_lock;

do $$
declare
  v_race record;
begin
  for v_race in
    select id, name, has_sprint
    from public.races
    where season_id = 2026
      and name in (
        'Australian Grand Prix',
        'Chinese Grand Prix',
        'Japanese Grand Prix',
        'Miami Grand Prix'
      )
    order by round
  loop
    perform public.score_race(v_race.id);
    perform public.evaluate_race_badges(v_race.id);
	    if v_race.has_sprint then
	      perform public.score_sprint(v_race.id);
	      perform public.evaluate_sprint_badges(v_race.id);
	    end if;
  end loop;
end$$;

commit;

select 'Arkadaşlar Ligi üye sayısı' as metrik,
       count(*)::text as deger
from public.league_memberships lm
where lm.league_id = (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
);

select 'Ana yarış tahmin özeti' as metrik,
       r.name as gp,
       string_agg(pr.username || ':' || coalesce(p.score::text, 'skorsuz'), ', ' order by lower(pr.username)) as tahmin_yapanlar
from public.races r
join public.predictions p on p.race_id = r.id
join public.profiles pr on pr.id = p.user_id
where p.league_id = (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
)
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  )
group by r.round, r.name
order by r.round;

select 'Ana yarış eksik tahmin' as metrik,
       r.name as gp,
       coalesce(string_agg(pr.username, ', ' order by lower(pr.username)), '-') as tahmin_yapmayanlar
from public.races r
join public.leagues l on l.id = (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
)
join public.league_memberships lm on lm.league_id = l.id
join public.profiles pr on pr.id = lm.user_id
left join public.predictions p
  on p.league_id = l.id
 and p.race_id = r.id
 and p.user_id = pr.id
where r.season_id = 2026
  and r.name in (
    'Australian Grand Prix',
    'Chinese Grand Prix',
    'Japanese Grand Prix',
    'Miami Grand Prix'
  )
  and p.id is null
group by r.round, r.name
order by r.round;

select 'Sprint tahmin özeti' as metrik,
       r.name as gp,
       string_agg(pr.username || ':' || coalesce(sp.score::text, 'skorsuz'), ', ' order by lower(pr.username)) as tahmin_yapanlar
from public.races r
join public.sprint_predictions sp on sp.race_id = r.id
join public.profiles pr on pr.id = sp.user_id
where sp.league_id = (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
)
  and r.name in ('Chinese Grand Prix', 'Miami Grand Prix')
group by r.round, r.name
order by r.round;

select 'Sprint eksik tahmin' as metrik,
       r.name as gp,
       coalesce(string_agg(pr.username, ', ' order by lower(pr.username)), '-') as tahmin_yapmayanlar
from public.races r
join public.leagues l on l.id = (
  select id
  from public.leagues
  where invite_code = 'RS38SVPJ'
  limit 1
)
join public.league_memberships lm on lm.league_id = l.id
join public.profiles pr on pr.id = lm.user_id
left join public.sprint_predictions sp
  on sp.league_id = l.id
 and sp.race_id = r.id
 and sp.user_id = pr.id
where r.season_id = 2026
  and r.name in ('Chinese Grand Prix', 'Miami Grand Prix')
  and sp.id is null
group by r.round, r.name
order by r.round;

select 'Rozet özeti' as metrik,
       pr.username,
       count(ub.id)::int as rozet_sayisi
from public.profiles pr
left join public.user_badges ub on ub.user_id = pr.id
group by pr.id, pr.username
order by rozet_sayisi desc, lower(pr.username)
limit 12;
