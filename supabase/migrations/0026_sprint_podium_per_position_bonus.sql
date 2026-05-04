-- 0026: Sprint podium scoring now mirrors main race format —
-- isim (any podium slot) +4, sıra (correct slot) +1, tam (all 3 in order) +2.

create or replace function public.compute_sprint_score(
  p_pred public.sprint_predictions,
  p_res public.sprint_results
) returns integer language plpgsql immutable as $$
declare
  v_score integer := 0;
  v_podium_set uuid[];
  v_pred_podium uuid[];
  v_res_podium uuid[];
begin
  if p_pred.winner_driver_id is not null and p_pred.winner_driver_id = p_res.p1 then
    v_score := v_score + 8;
  end if;

  v_podium_set := array[p_res.p1, p_res.p2, p_res.p3];
  v_pred_podium := array[p_pred.p1_id, p_pred.p2_id, p_pred.p3_id];
  v_res_podium := array[p_res.p1, p_res.p2, p_res.p3];

  for i in 1..3 loop
    if v_pred_podium[i] is not null and v_pred_podium[i] = any(v_podium_set) then
      v_score := v_score + 4;
    end if;
    if v_pred_podium[i] is not null and v_pred_podium[i] = v_res_podium[i] then
      v_score := v_score + 1;
    end if;
  end loop;

  if p_pred.p1_id is not null
     and p_pred.p1_id = p_res.p1
     and p_pred.p2_id = p_res.p2
     and p_pred.p3_id = p_res.p3 then
    v_score := v_score + 2;
  end if;

  if p_pred.top_team_id is not null and p_pred.top_team_id = p_res.top_team_id then
    v_score := v_score + 8;
  end if;

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

  if p_pred.safety_car is not null and p_pred.safety_car = p_res.safety_car then
    v_score := v_score + 2;
  end if;

  return v_score;
end$$;
