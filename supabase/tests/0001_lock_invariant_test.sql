-- pgTAP — kilit invariant'ı ve RLS politika testleri
begin;
select plan(9);

-- Setup: bir test sezonu, yarış, sürücü
insert into public.seasons (id, is_active) values (9999, true);
insert into public.teams (season_id, code, name) values (9999, 'TST', 'Test Team');
insert into public.drivers (season_id, code, full_name, team_id)
select 9999, 'TD1', 'Test Driver 1', id from public.teams where season_id = 9999 and code = 'TST';
insert into public.drivers (season_id, code, full_name, team_id)
select 9999, 'TD2', 'Test Driver 2', id from public.teams where season_id = 9999 and code = 'TST';

-- Geçmiş bir yarış (lock_at çoktan geçmiş)
insert into public.races (season_id, round, name, circuit, qualifying_at, race_at)
values (9999, 1, 'Past Race', 'Test', now() - interval '1 day', now() - interval '23 hours');

-- Gelecek bir yarış
insert into public.races (season_id, round, name, circuit, qualifying_at, race_at)
values (9999, 2, 'Future Race', 'Test', now() + interval '7 days', now() + interval '8 days');

-- Auth ortamı simülasyonu için service role kullanıyoruz; direct DB testleri.
-- Bir test profili
insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000001', 'test@example.com')
  on conflict (id) do nothing;
insert into public.profiles (id, username) values ('00000000-0000-0000-0000-000000000001', 'tester1')
  on conflict (id) do nothing;
insert into public.leagues (id, name, owner_id, invite_code, season_id)
values (
  '00000000-0000-0000-0000-000000009999',
  'Test League',
  '00000000-0000-0000-0000-000000000001',
  'TST001AA',
  9999
)
on conflict (id) do nothing;
insert into public.leagues (id, name, owner_id, invite_code, season_id)
values (
  '00000000-0000-0000-0000-000000009998',
  'Second Test League',
  '00000000-0000-0000-0000-000000000001',
  'TST002AA',
  9999
)
on conflict (id) do nothing;

-- 1) lock_at geçmiş yarışa tahmin yazma yasağı
prepare past_pred as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  select '00000000-0000-0000-0000-000000000001',
         '00000000-0000-0000-0000-000000009999',
         id,
         (select id from public.drivers where code='TD1' and season_id=9999)
  from public.races where season_id=9999 and round=1;
select throws_ok('past_pred', 'P0001', null, 'Past race rejects predictions');

-- 2) Gelecek yarışa tahmin yazılabilir
prepare future_pred as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id, p1_id, p2_id, p3_id, dnf_count)
  select '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000009999',
    id,
    (select id from public.drivers where code='TD1' and season_id=9999),
    (select id from public.drivers where code='TD1' and season_id=9999),
    (select id from public.drivers where code='TD2' and season_id=9999),
    null,
    3
  from public.races where season_id=9999 and round=2;
select lives_ok('future_pred', 'Future race accepts predictions');

-- 3) Aynı (user, race) için ikinci insert UNIQUE patlatır
prepare dup_pred as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  select '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000009999',
    id,
    (select id from public.drivers where code='TD1' and season_id=9999)
  from public.races where season_id=9999 and round=2;
select throws_ok('dup_pred', '23505', null, 'Duplicate prediction rejected');

-- 4) Aynı (user, race) başka ligde ayrı tahmin olarak yazılabilir
prepare other_league_pred as
  insert into public.predictions (user_id, league_id, race_id, winner_driver_id)
  select '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000009998',
    id,
    (select id from public.drivers where code='TD2' and season_id=9999)
  from public.races where season_id=9999 and round=2;
select lives_ok('other_league_pred', 'Same race accepts separate prediction per league');

-- 5) p1=p2 yasağı
prepare same_p1p2 as
  update public.predictions
  set p1_id = (select id from public.drivers where code='TD1' and season_id=9999),
      p2_id = (select id from public.drivers where code='TD1' and season_id=9999),
      p3_id = (select id from public.drivers where code='TD2' and season_id=9999)
  where user_id = '00000000-0000-0000-0000-000000000001'
    and race_id = (select id from public.races where season_id=9999 and round=2);
select throws_like('same_p1p2', '%P1 and P2 must be different%', 'p1==p2 yasak');

-- 6) Skor formülü (immutable, rule-by-rule)
-- Tam podium + winner + top team + pole + dnf doğru + safety car + joker doğru
-- = 10 + (3*5 + 3*2 + 3) + 10 + 8 + 6 + 3 + 12 = 73
do $$
declare
  v_pred public.predictions;
  v_res  public.race_results;
  v_d1 uuid; v_d2 uuid;
  v_team uuid;
  v_league uuid := '00000000-0000-0000-0000-000000009999';
begin
  select id into v_d1 from public.drivers where code='TD1' and season_id=9999;
  select id into v_d2 from public.drivers where code='TD2' and season_id=9999;
  select id into v_team from public.teams where code='TST' and season_id=9999;
  v_pred := row(
    gen_random_uuid(), '00000000-0000-0000-0000-000000000001', gen_random_uuid(),
    v_d1, v_d1, v_d2, v_d1, v_d1, v_d1, 3, 'Yes',
    null, null, now(), now(), v_league, v_team, true
  )::public.predictions;
  v_res := row(
    gen_random_uuid(), v_d1, v_d2, v_d1, v_d1, v_d1, 3, 'Yes', now(), v_team, true
  )::public.race_results;
  perform set_config('test.score_perfect',
    public.compute_prediction_score(v_pred, v_res, 12)::text, true);
end$$;
select is(current_setting('test.score_perfect')::int, 73, 'Perfect prediction = 73');

-- 7) Hiç doğru yoksa 0
-- Pred her şeyi v_d2 tahmin ediyor, sonuçlar tamamı v_d1.
-- Pred dnf=0, gerçek dnf=5 (>1 fark), joker mismatch.
do $$
declare
  v_pred public.predictions;
  v_res  public.race_results;
  v_d1 uuid; v_d2 uuid;
  v_team uuid;
  v_league uuid := '00000000-0000-0000-0000-000000009999';
begin
  select id into v_d1 from public.drivers where code='TD1' and season_id=9999;
  select id into v_d2 from public.drivers where code='TD2' and season_id=9999;
  select id into v_team from public.teams where code='TST' and season_id=9999;
  v_pred := row(
    gen_random_uuid(), '00000000-0000-0000-0000-000000000001', gen_random_uuid(),
    v_d2, v_d2, v_d2, v_d2, v_d2, v_d2, 0, 'No',
    null, null, now(), now(), v_league, null, false
  )::public.predictions;
  v_res := row(
    gen_random_uuid(), v_d1, v_d1, v_d1, v_d1, v_d1, 5, 'Yes', now(), v_team, true
  )::public.race_results;
  perform set_config('test.score_zero',
    public.compute_prediction_score(v_pred, v_res, 12)::text, true);
end$$;
select is(current_setting('test.score_zero')::int, 0, 'No correct picks = 0');

-- 8) score_race fonksiyonu race_results insert'i ile auto-tetikleniyor mu?
update public.races set qualifying_at = now() + interval '5 minutes',
                       race_at = now() + interval '6 minutes'
  where season_id=9999 and round=2;
-- Şimdi tahmin var, yarış sonuçlarını ekle
insert into public.race_results (race_id, p1, p2, p3, pole, fastest_lap, dnf_count, joker_correct)
select r.id,
  (select id from public.drivers where code='TD1' and season_id=9999),
  (select id from public.drivers where code='TD2' and season_id=9999),
  (select id from public.drivers where code='TD1' and season_id=9999),
  (select id from public.drivers where code='TD1' and season_id=9999),
  (select id from public.drivers where code='TD1' and season_id=9999),
  3, 'Yes'
from public.races r where season_id=9999 and round=2;

select isnt(
  (select score from public.predictions where user_id='00000000-0000-0000-0000-000000000001'
     and league_id='00000000-0000-0000-0000-000000009999'
     and race_id=(select id from public.races where season_id=9999 and round=2)),
  null,
  'score auto-set after race_results insert'
);

-- 9) Yarış status finished'a geçti mi
select is(
  (select status::text from public.races where season_id=9999 and round=2),
  'finished',
  'Race status flipped to finished after scoring'
);

select * from finish();
rollback;
