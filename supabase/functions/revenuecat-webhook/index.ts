import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type RevenueCatEvent = {
  type?: string;
  app_user_id?: string;
  product_id?: string;
  entitlement_ids?: string[];
  expiration_at_ms?: number | null;
  purchased_at_ms?: number | null;
  original_transaction_id?: string | null;
  transaction_id?: string | null;
  store?: string | null;
};

function statusFor(type: string | undefined): string {
  switch ((type ?? '').toUpperCase()) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
    case 'SUBSCRIPTION_EXTENDED':
    case 'PRODUCT_CHANGE':
      return 'active';
    case 'TRIAL_STARTED':
      return 'trialing';
    case 'BILLING_ISSUE':
    case 'GRACE_PERIOD':
      return 'grace_period';
    case 'CANCELLATION':
      return 'canceled';
    case 'EXPIRATION':
      return 'expired';
    default:
      return 'expired';
  }
}

function isoFromMs(value: number | null | undefined): string | null {
  return value == null ? null : new Date(value).toISOString();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: corsHeaders });
  }

  const expectedAuth = Deno.env.get('REVENUECAT_WEBHOOK_AUTH');
  const providedAuth = req.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!expectedAuth || providedAuth !== expectedAuth) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const payload = await req.json();
  const event = (payload.event ?? payload) as RevenueCatEvent;
  const userId = event.app_user_id;
  const entitlements = event.entitlement_ids ?? [];
  // Accept any of the configured entitlement IDs from RevenueCat. The
  // dashboard entitlement is named "GridCall Pro" but the DB column stores
  // the canonical 'premium' tier — so we match either spelling and persist
  // 'premium'. PREMIUM_ENTITLEMENT_IDS lets ops add more without a redeploy.
  const acceptedEntitlements = (
    Deno.env.get('PREMIUM_ENTITLEMENT_IDS') ?? 'premium,GridCall Pro,gridcall_pro'
  )
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const hasPremium = entitlements.some((e) =>
    acceptedEntitlements.some(
      (accepted) => accepted.toLowerCase() === e.toLowerCase(),
    ),
  );
  if (!userId || !hasPremium) {
    return Response.json({ ok: true, ignored: true }, { headers: corsHeaders });
  }

  const status = statusFor(event.type);
  const source = event.store?.toLowerCase().includes('play')
    ? 'play_store'
    : event.store?.toLowerCase().includes('app')
    ? 'app_store'
    : 'revenuecat';

  // Verify the app_user_id maps to an existing auth user. RevenueCat
  // sandbox testing or cross-environment app installs (e.g. a local-Supabase
  // app pointing its purchases at the production webhook) will send IDs that
  // don't exist here, which would 23503 FK-violate the upsert and surface as
  // 100% error rate in RC even though nothing is actually broken.
  const { data: userRow } = await supabase
    .from('profiles')
    .select('id')
    .eq('id', userId)
    .maybeSingle();

  if (!userRow) {
    console.warn(
      `revenuecat-webhook: skipping ${event.type} for unknown user ${userId}`,
    );
    return Response.json(
      { ok: true, skipped: 'unknown_user' },
      { headers: corsHeaders },
    );
  }

  const { error } = await supabase.from('user_entitlements').upsert(
    {
      user_id: userId,
      entitlement: 'premium',
      source,
      product_id: event.product_id,
      original_transaction_id: event.original_transaction_id,
      store_subscription_id: event.transaction_id,
      status,
      current_period_start: isoFromMs(event.purchased_at_ms),
      current_period_end: isoFromMs(event.expiration_at_ms),
      updated_at: new Date().toISOString(),
    },
    {
      onConflict: 'user_id,entitlement,source,store_identity',
    },
  );

  if (error) {
    console.error('revenuecat-webhook upsert failed:', error);
    return Response.json({ ok: false, error: error.message }, {
      status: 500,
      headers: corsHeaders,
    });
  }

  return Response.json({ ok: true }, { headers: corsHeaders });
});
