-- Remove any leftover development premium entitlements from environments where
-- the old dev toggle was used before the free public release.
do $$
begin
  if to_regprocedure('public.dev_toggle_premium()') is not null then
    revoke execute on function public.dev_toggle_premium() from authenticated;
  end if;
end;
$$;

update public.profiles p
set tier = 'free'::public.user_tier
where p.tier = 'premium'::public.user_tier
  and exists (
    select 1
    from public.subscriptions s
    where s.user_id = p.id
      and s.provider = 'manual'
      and s.product_id = 'dev_toggle'
  );

delete from public.subscriptions
where provider = 'manual'
  and product_id = 'dev_toggle';

drop function if exists public.dev_toggle_premium();
