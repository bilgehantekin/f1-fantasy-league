-- 0017: Sprint tahmin lock trigger'ı, score_sprint sırasında yapılan
-- yalnızca-score güncellemelerini engelliyordu. Ana yarış lock trigger'ında
-- olduğu gibi (0003), kullanıcı tahmin alanları değişmemişse muaf tut.

create or replace function public.assert_sprint_pred_unlocked()
returns trigger language plpgsql as $$
declare
  v_lock_at timestamptz;
  v_has_sprint boolean;
begin
  if TG_OP = 'UPDATE'
     and new.user_id = old.user_id
     and new.race_id = old.race_id
     and new.league_id is not distinct from old.league_id
     and new.winner_driver_id is not distinct from old.winner_driver_id
     and new.p1_id is not distinct from old.p1_id
     and new.p2_id is not distinct from old.p2_id
     and new.p3_id is not distinct from old.p3_id
     and new.pole_driver_id is not distinct from old.pole_driver_id
     and new.dnf_count is not distinct from old.dnf_count then
    return new;
  end if;

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
  if new.p1_id is not null and new.p1_id = new.p2_id then
    raise exception 'P1 and P2 must be different drivers';
  end if;
  if new.p1_id is not null and new.p1_id = new.p3_id then
    raise exception 'P1 and P3 must be different drivers';
  end if;
  if new.p2_id is not null and new.p2_id = new.p3_id then
    raise exception 'P2 and P3 must be different drivers';
  end if;
  return new;
end$$;
