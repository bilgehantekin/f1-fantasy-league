import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Cron-driven deletion processor. For each deletion request whose grace
// period has elapsed:
//   1) Wipe user-owned rows via process_account_deletion(user_id).
//   2) Delete the auth.users entry via the admin API.
//   3) Mark the request as completed.
//
// Idempotent: if the auth user is already gone we still complete the request.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: requests, error: findError } = await client.rpc(
    "find_processable_deletion_requests",
  );
  if (findError) return json({ error: findError.message }, 500);

  const processed: Array<{ id: string; user_id: string; ok: boolean; note?: string }> = [];

  for (const row of (requests ?? []) as Array<{ id: string; user_id: string }>) {
    try {
      const { error: wipeError } = await client.rpc(
        "process_account_deletion",
        { p_user_id: row.user_id },
      );
      if (wipeError) {
        processed.push({ id: row.id, user_id: row.user_id, ok: false, note: wipeError.message });
        continue;
      }

      const { error: authError } = await client.auth.admin.deleteUser(row.user_id);
      if (authError && !/User not found/i.test(authError.message)) {
        processed.push({ id: row.id, user_id: row.user_id, ok: false, note: authError.message });
        continue;
      }

      const { error: completeError } = await client.rpc(
        "complete_deletion_request",
        { p_request_id: row.id },
      );
      if (completeError) {
        processed.push({ id: row.id, user_id: row.user_id, ok: false, note: completeError.message });
        continue;
      }

      processed.push({ id: row.id, user_id: row.user_id, ok: true });
    } catch (err) {
      processed.push({
        id: row.id,
        user_id: row.user_id,
        ok: false,
        note: err instanceof Error ? err.message : String(err),
      });
    }
  }

  return json({ processed_count: processed.length, processed });
});

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
