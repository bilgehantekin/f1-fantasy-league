import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Cron her dakika çalışır: yarış statülerini ilerletir
//   upcoming → locked (lock_at geçti)
//   locked   → live    (race_at geçti)
//   live     → finished (race_at + 4h geçti)
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await client.rpc("advance_race_statuses");
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: sprintData, error: sprintErr } = await client.rpc(
    "advance_sprint_statuses",
  );
  if (sprintErr) {
    return new Response(JSON.stringify({ error: sprintErr.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      transitions: data ?? [],
      sprint_transitions: sprintData ?? [],
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
