-- 0027: Joker becomes visible 1 day before lock; allow users to clear their
-- own main-race prediction; null out joker selections that were made under
-- the old (always-visible) rule.

-- Owner delete policy for main predictions (sprint_predictions already has one).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'predictions'
      and policyname = 'predictions_delete_self'
  ) then
    create policy "predictions_delete_self" on public.predictions
      for delete using (user_id = auth.uid());
  end if;
end$$;

-- Clear joker_option for predictions whose race lock is more than 24 hours
-- away — under the new rule the joker shouldn't have been answerable yet.
alter table public.predictions disable trigger predictions_enforce_lock;

update public.predictions p
set joker_option = null
from public.races r
where p.race_id = r.id
  and p.joker_option is not null
  and r.lock_at > now() + interval '24 hours';

alter table public.predictions enable trigger predictions_enforce_lock;
