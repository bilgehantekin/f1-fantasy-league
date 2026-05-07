-- 0033: Rozet sistemini düzenle.
-- - Hız Şeytanı rozetini kaldır (uygulamada en hızlı tur sorusu yok).
-- - Sprint için ayrı rozet varyantları ekle.
-- - Üçlü Seri rozetini ana yarış ve sprint için ayrı ayrı uygula.
-- - sprint_results trigger'ına rozet değerlendirmesi ekle.
-- - Geriye dönük olarak tüm finalize edilmiş yarış ve sprintleri yeniden değerlendir.

begin;

-- 1) Hız Şeytanı rozetini sil (cascade ile bağlı user_badges kayıtları silinir).
delete from public.badges where code = 'fastest_caller';

-- 2) Sprint rozet varyantları (mevcut ana yarış rozetlerinin sprint karşılıkları).
insert into public.badges (code, name, description, icon, rarity) values
  ('sprint_pole_caller',     'Sprint Pole Avcısı',     'Bir sprintte pole pozisyonunu doğru bil',                '🏁', 'common'),
  ('sprint_dnf_oracle',      'Sprint DNF Kahini',      'Bir sprintte DNF sayısını tam bil',                      '🔮', 'rare'),
  ('sprint_bullseye_podium', 'Sprint Bullseye',        'Bir sprintte podium sıralamasını tam doğru bil',         '🎯', 'epic'),
  ('sprint_weekly_winner',   'Sprint Hafta Şampiyonu', 'Bir ligde sprintin haftalık 1.-si ol',                   '🏆', 'epic'),
  ('sprint_perfect_week',    'Mükemmel Sprint',        'Bir sprintteki tüm soruları doğru bil',                  '⭐', 'legendary'),
  ('sprint_three_in_row',    'Sprint Üçlü Seri',       'Üst üste 3 sprintte podium tahmini doğru',               '🔥', 'rare')
on conflict (code) do nothing;

-- 3) Ana yarış rozet değerlendirmesi (Hız Şeytanı kaldırıldı, Üçlü Seri eklendi).
create or replace function public.evaluate_race_badges(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.race_results;
  v_pred public.predictions;
  v_curr_round int;
  v_award int := 0;
  v_id_perfect uuid;
  v_id_bullseye uuid;
  v_id_joker uuid;
  v_id_dnf uuid;
  v_id_pole uuid;
  v_id_winner uuid;
  v_id_three uuid;
  v_prev_race_1 uuid;
  v_prev_race_2 uuid;
  v_prev_round_1 int;
begin
  select * into v_res from public.race_results where race_id = p_race_id;
  if not found then return 0; end if;

  select round into v_curr_round from public.races where id = p_race_id;

  select id into v_id_perfect  from public.badges where code='perfect_week';
  select id into v_id_bullseye from public.badges where code='bullseye_podium';
  select id into v_id_joker    from public.badges where code='joker_master';
  select id into v_id_dnf      from public.badges where code='dnf_oracle';
  select id into v_id_pole     from public.badges where code='pole_caller';
  select id into v_id_winner   from public.badges where code='weekly_winner';
  select id into v_id_three    from public.badges where code='three_in_row';

  -- Üçlü seri için: bu yarıştan önceki, race_results'ı olan iki yarış.
  select r.id, r.round into v_prev_race_1, v_prev_round_1
    from public.races r
    join public.race_results rr on rr.race_id = r.id
   where r.round < v_curr_round
   order by r.round desc
   limit 1;

  if v_prev_round_1 is not null then
    select r.id into v_prev_race_2
      from public.races r
      join public.race_results rr on rr.race_id = r.id
     where r.round < v_prev_round_1
     order by r.round desc
     limit 1;
  end if;

  for v_pred in select * from public.predictions where race_id = p_race_id loop
    -- bullseye_podium: p1/p2/p3 sırasıyla doğru
    if v_id_bullseye is not null
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3 then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_bullseye, p_race_id) on conflict do nothing;
      v_award := v_award + 1;

      -- three_in_row: önceki iki ana yarışta da bullseye almış olmalı
      if v_id_three is not null and v_prev_race_1 is not null and v_prev_race_2 is not null
         and exists (
           select 1 from public.user_badges ub
           where ub.user_id = v_pred.user_id and ub.badge_id = v_id_bullseye
             and ub.race_id = v_prev_race_1
         )
         and exists (
           select 1 from public.user_badges ub
           where ub.user_id = v_pred.user_id and ub.badge_id = v_id_bullseye
             and ub.race_id = v_prev_race_2
         ) then
        insert into public.user_badges (user_id, badge_id, race_id)
        values (v_pred.user_id, v_id_three, p_race_id) on conflict do nothing;
        v_award := v_award + 1;
      end if;
    end if;

    if v_id_joker is not null
       and v_pred.joker_option is not null and v_res.joker_correct is not null
       and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_joker, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_dnf is not null
       and v_pred.dnf_count is not null and v_pred.dnf_count = v_res.dnf_count then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_dnf, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_pole is not null
       and v_pred.pole_driver_id = v_res.pole then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_pole, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_perfect is not null
       and v_pred.winner_driver_id = v_res.p1
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3
       and v_pred.top_team_id is not distinct from v_res.top_team_id
       and v_pred.pole_driver_id = v_res.pole
       and v_pred.dnf_count = v_res.dnf_count
       and v_pred.safety_car is not distinct from v_res.safety_car
       and v_pred.joker_option is not null and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_perfect, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
  end loop;

  -- weekly_winner: her ligin haftalık 1.-leri
  insert into public.user_badges (user_id, badge_id, race_id)
  select distinct p.user_id, v_id_winner, p_race_id
  from public.predictions p
  join public.league_memberships m
    on m.user_id = p.user_id
   and m.league_id = p.league_id
  where v_id_winner is not null
    and p.race_id = p_race_id and p.score is not null
    and p.score = (
      select max(p2.score) from public.predictions p2
      where p2.race_id = p_race_id
        and p2.league_id = m.league_id
        and p2.score is not null
    )
  on conflict do nothing;

  return v_award;
end$$;
grant execute on function public.evaluate_race_badges(uuid) to service_role;

-- 4) Sprint rozet değerlendirmesi (ana yarışla aynı mantık, sprint varyantları).
create or replace function public.evaluate_sprint_badges(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.sprint_results;
  v_pred public.sprint_predictions;
  v_curr_round int;
  v_award int := 0;
  v_id_perfect uuid;
  v_id_bullseye uuid;
  v_id_dnf uuid;
  v_id_pole uuid;
  v_id_winner uuid;
  v_id_three uuid;
  v_prev_race_1 uuid;
  v_prev_race_2 uuid;
  v_prev_round_1 int;
begin
  select * into v_res from public.sprint_results where race_id = p_race_id;
  if not found then return 0; end if;

  select round into v_curr_round from public.races where id = p_race_id;

  select id into v_id_perfect  from public.badges where code='sprint_perfect_week';
  select id into v_id_bullseye from public.badges where code='sprint_bullseye_podium';
  select id into v_id_dnf      from public.badges where code='sprint_dnf_oracle';
  select id into v_id_pole     from public.badges where code='sprint_pole_caller';
  select id into v_id_winner   from public.badges where code='sprint_weekly_winner';
  select id into v_id_three    from public.badges where code='sprint_three_in_row';

  -- Üçlü seri için: bu sprintten önceki, sprint_results'ı olan iki yarış.
  select r.id, r.round into v_prev_race_1, v_prev_round_1
    from public.races r
    join public.sprint_results sr on sr.race_id = r.id
   where r.round < v_curr_round
   order by r.round desc
   limit 1;

  if v_prev_round_1 is not null then
    select r.id into v_prev_race_2
      from public.races r
      join public.sprint_results sr on sr.race_id = r.id
     where r.round < v_prev_round_1
     order by r.round desc
     limit 1;
  end if;

  for v_pred in select * from public.sprint_predictions where race_id = p_race_id loop
    if v_id_bullseye is not null
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3 then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_bullseye, p_race_id) on conflict do nothing;
      v_award := v_award + 1;

      if v_id_three is not null and v_prev_race_1 is not null and v_prev_race_2 is not null
         and exists (
           select 1 from public.user_badges ub
           where ub.user_id = v_pred.user_id and ub.badge_id = v_id_bullseye
             and ub.race_id = v_prev_race_1
         )
         and exists (
           select 1 from public.user_badges ub
           where ub.user_id = v_pred.user_id and ub.badge_id = v_id_bullseye
             and ub.race_id = v_prev_race_2
         ) then
        insert into public.user_badges (user_id, badge_id, race_id)
        values (v_pred.user_id, v_id_three, p_race_id) on conflict do nothing;
        v_award := v_award + 1;
      end if;
    end if;

    if v_id_dnf is not null
       and v_pred.dnf_count is not null and v_pred.dnf_count = v_res.dnf_count then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_dnf, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_pole is not null
       and v_pred.pole_driver_id = v_res.pole then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_pole, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    if v_id_perfect is not null
       and v_pred.winner_driver_id = v_res.p1
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3
       and v_pred.top_team_id is not distinct from v_res.top_team_id
       and v_pred.pole_driver_id = v_res.pole
       and v_pred.dnf_count = v_res.dnf_count
       and v_pred.safety_car is not distinct from v_res.safety_car then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_perfect, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
  end loop;

  -- sprint_weekly_winner
  insert into public.user_badges (user_id, badge_id, race_id)
  select distinct sp.user_id, v_id_winner, p_race_id
  from public.sprint_predictions sp
  join public.league_memberships m
    on m.user_id = sp.user_id
   and m.league_id = sp.league_id
  where v_id_winner is not null
    and sp.race_id = p_race_id and sp.score is not null
    and sp.score = (
      select max(sp2.score) from public.sprint_predictions sp2
      where sp2.race_id = p_race_id
        and sp2.league_id = m.league_id
        and sp2.score is not null
    )
  on conflict do nothing;

  return v_award;
end$$;
grant execute on function public.evaluate_sprint_badges(uuid) to service_role;

-- 5) sprint_results trigger'ı: skor + rozet
create or replace function public.handle_sprint_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.score_sprint(new.race_id);
  perform public.evaluate_sprint_badges(new.race_id);
  return new;
end$$;

-- 6) Geriye dönük rozet değerlendirmesi (round sırasıyla, three_in_row chainini kurmak için).
do $$
declare
  v_race_id uuid;
begin
  for v_race_id in
    select rr.race_id
      from public.race_results rr
      join public.races r on r.id = rr.race_id
     order by r.round
  loop
    perform public.evaluate_race_badges(v_race_id);
  end loop;
  for v_race_id in
    select sr.race_id
      from public.sprint_results sr
      join public.races r on r.id = sr.race_id
     order by r.round
  loop
    perform public.evaluate_sprint_badges(v_race_id);
  end loop;
end$$;

commit;
