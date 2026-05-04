-- GridCall — Premium üyelik

create type public.user_tier as enum ('free', 'premium');

alter table public.profiles add column tier public.user_tier not null default 'free';

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  provider text not null check (provider in ('revenuecat','stripe','manual')),
  product_id text,
  status text not null check (status in ('active','expired','cancelled','trialing')),
  current_period_end timestamptz,
  external_id text,                    -- RevenueCat appUserID veya Stripe subscription_id
  raw jsonb,                            -- webhook payload arşivi
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger subscriptions_updated_at before update on public.subscriptions
  for each row execute function public.set_updated_at();

alter table public.subscriptions enable row level security;
create policy "subscriptions_read_self" on public.subscriptions for select
  using (user_id = auth.uid());
-- Sadece service role yazar (webhook entegrasyonu)

-- profiles.tier policy: kendi tier'ını görür ama yazamaz (sadece subscription trigger güncelleyebilir)
-- profiles_update_self policy zaten var ama tier kolonunu hariç tutmamız gerek.
-- Workaround: trigger ile kullanıcının tier alanını değiştirmesini engelle.
create or replace function public.protect_profile_tier()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'UPDATE' and old.tier is distinct from new.tier then
    -- service_role bypass eder (RLS off), normal kullanıcılar geri alır
    if current_setting('request.jwt.claims', true)::jsonb->>'role' <> 'service_role' then
      new.tier := old.tier;
    end if;
  end if;
  return new;
end$$;
create trigger profiles_protect_tier
  before update on public.profiles
  for each row execute function public.protect_profile_tier();

-- Subscription değiştiğinde profile.tier'ı senkronla
create or replace function public.sync_tier_from_subscription()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set tier = case
    when new.status in ('active','trialing') then 'premium'::public.user_tier
    else 'free'::public.user_tier
  end
  where id = new.user_id;
  return new;
end$$;
create trigger subscriptions_sync_tier
  after insert or update on public.subscriptions
  for each row execute function public.sync_tier_from_subscription();

-- Dev için: kullanıcı kendine premium toggle eden RPC (production'da kapatılır)
create or replace function public.dev_toggle_premium()
returns text language plpgsql security definer set search_path = public as $$
declare
  v_user uuid;
  v_current public.user_tier;
  v_new public.user_tier;
begin
  v_user := auth.uid();
  if v_user is null then
    raise exception 'auth required';
  end if;
  select tier into v_current from public.profiles where id = v_user;
  v_new := case when v_current = 'free' then 'premium'::public.user_tier else 'free'::public.user_tier end;

  insert into public.subscriptions (user_id, provider, product_id, status, current_period_end, external_id)
  values (v_user, 'manual', 'dev_toggle',
    case when v_new = 'premium' then 'active' else 'cancelled' end,
    case when v_new = 'premium' then now() + interval '30 days' else now() end,
    'dev_' || v_user::text)
  on conflict (user_id) do update
    set status = excluded.status,
        current_period_end = excluded.current_period_end,
        provider = 'manual',
        updated_at = now();

  return v_new::text;
end$$;
grant execute on function public.dev_toggle_premium() to authenticated;
