-- PitWall — yarış sonrası rozet değerlendirme

create or replace function public.evaluate_race_badges(p_race_id uuid)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_res public.race_results;
  v_pred public.predictions;
  v_award int := 0;
  v_id_perfect uuid;
  v_id_bullseye uuid;
  v_id_joker uuid;
  v_id_dnf uuid;
  v_id_pole uuid;
  v_id_fl uuid;
  v_id_winner uuid;
begin
  select * into v_res from public.race_results where race_id = p_race_id;
  if not found then return 0; end if;

  select id into v_id_perfect  from public.badges where code='perfect_week';
  select id into v_id_bullseye from public.badges where code='bullseye_podium';
  select id into v_id_joker    from public.badges where code='joker_master';
  select id into v_id_dnf      from public.badges where code='dnf_oracle';
  select id into v_id_pole     from public.badges where code='pole_caller';
  select id into v_id_fl       from public.badges where code='fastest_caller';
  select id into v_id_winner   from public.badges where code='weekly_winner';

  -- Per-prediction rozetleri
  for v_pred in select * from public.predictions where race_id = p_race_id loop
    -- bullseye_podium: p1/p2/p3 sırasıyla doğru
    if v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3 then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_bullseye, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    -- joker_master
    if v_pred.joker_option is not null and v_res.joker_correct is not null
       and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_joker, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    -- dnf_oracle (tam sayı)
    if v_pred.dnf_count is not null and v_pred.dnf_count = v_res.dnf_count then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_dnf, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    -- pole_caller
    if v_pred.pole_driver_id = v_res.pole then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_pole, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    -- fastest_caller
    if v_pred.fastest_lap_driver_id = v_res.fastest_lap then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_fl, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
    -- perfect_week: hepsi doğru
    if v_pred.winner_driver_id = v_res.p1
       and v_pred.p1_id = v_res.p1 and v_pred.p2_id = v_res.p2 and v_pred.p3_id = v_res.p3
       and v_pred.pole_driver_id = v_res.pole
       and v_pred.fastest_lap_driver_id = v_res.fastest_lap
       and v_pred.dnf_count = v_res.dnf_count
       and v_pred.joker_option is not null and v_pred.joker_option = v_res.joker_correct then
      insert into public.user_badges (user_id, badge_id, race_id)
      values (v_pred.user_id, v_id_perfect, p_race_id) on conflict do nothing;
      v_award := v_award + 1;
    end if;
  end loop;

  -- weekly_winner: her ligin haftalık 1.-leri (skor null olanları sayma)
  insert into public.user_badges (user_id, badge_id, race_id)
  select distinct p.user_id, v_id_winner, p_race_id
  from public.predictions p
  join public.league_memberships m on m.user_id = p.user_id
  where p.race_id = p_race_id and p.score is not null
    and p.score = (
      select max(p2.score) from public.predictions p2
      join public.league_memberships m2 on m2.user_id = p2.user_id
      where p2.race_id = p_race_id and m2.league_id = m.league_id and p2.score is not null
    )
  on conflict do nothing;

  return v_award;
end$$;

grant execute on function public.evaluate_race_badges(uuid) to service_role;

-- Mevcut handle_race_result trigger'ını güncelle: scoring + badges
create or replace function public.handle_race_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.score_race(new.race_id);
  perform public.evaluate_race_badges(new.race_id);
  return new;
end$$;
