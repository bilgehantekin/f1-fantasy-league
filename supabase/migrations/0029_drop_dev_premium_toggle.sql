-- First public release has no premium/IAP surface. Keep the historical
-- subscription schema inert, but remove the development-only toggle RPC.
drop function if exists public.dev_toggle_premium();
