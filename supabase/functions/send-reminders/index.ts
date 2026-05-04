// Tahmin yapmamış kullanıcılara lock öncesi email hatırlatması gönderir.
//
// Çağırma: cron (her saat) veya elle POST.
// Pencereler: lock_at - 6h ± 30dk → reminder_6h, lock_at - 1h ± 30dk → reminder_1h.
// notifications_log UNIQUE constraint'i duplicate gönderimi engeller.
//
// Env vars:
//   RESEND_API_KEY  → set ise Resend ile gerçek email gönderir
//   REMINDER_FROM   → 'GridCall <noreply@example.com>' (Resend doğrulanmış domain)
//   yoksa: dry-run modu (yalnızca log yazar, mail gitmez — yerel dev için)

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

interface RaceRow {
  id: string;
  name: string;
  round: number;
  qualifying_at: string;
  lock_at: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const c = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const resendKey = Deno.env.get("RESEND_API_KEY");
  const fromAddr = Deno.env.get("REMINDER_FROM") ??
    "GridCall <noreply@gridcall.local>";
  const dryRun = !resendKey;

  // Pencerelere giren yarışlar
  const now = Date.now();
  const races6h = await racesInWindow(
    c,
    now + 5.5 * 3600_000,
    now + 6.5 * 3600_000,
  );
  const races1h = await racesInWindow(
    c,
    now + 0.5 * 3600_000,
    now + 1.5 * 3600_000,
  );

  const summary = {
    dry_run: dryRun,
    reminder_6h: { races: races6h.length, sent: 0, skipped: 0, errors: 0 },
    reminder_1h: { races: races1h.length, sent: 0, skipped: 0, errors: 0 },
  };

  for (const race of races6h) {
    await processRace(
      c,
      race,
      "reminder_6h",
      fromAddr,
      resendKey,
      summary.reminder_6h,
    );
  }
  for (const race of races1h) {
    await processRace(
      c,
      race,
      "reminder_1h",
      fromAddr,
      resendKey,
      summary.reminder_1h,
    );
  }

  return jsonResponse(summary);
});

async function racesInWindow(
  c: SupabaseClient,
  fromMs: number,
  toMs: number,
): Promise<RaceRow[]> {
  const { data, error } = await c
    .from("races")
    .select("id, name, round, qualifying_at, lock_at")
    .gte("lock_at", new Date(fromMs).toISOString())
    .lte("lock_at", new Date(toMs).toISOString());
  if (error) throw error;
  return (data ?? []) as RaceRow[];
}

interface UserToRemind {
  id: string;
  email: string;
  username: string;
  league_id: string;
  league_name: string;
}

async function findUsersMissingPrediction(
  c: SupabaseClient,
  raceId: string,
  kind: string,
): Promise<UserToRemind[]> {
  const { data: raceRows, error: raceErr } = await c
    .from("races")
    .select("season_id")
    .eq("id", raceId)
    .limit(1);
  if (raceErr) throw raceErr;
  const seasonId = raceRows?.[0]?.season_id;
  if (!seasonId) return [];

  const { data: memberships, error: membershipErr } = await c
    .from("league_memberships")
    .select("user_id, league_id, league:leagues!inner(name, season_id)")
    .eq("league.season_id", seasonId);
  if (membershipErr) throw membershipErr;
  const pairs = (memberships ?? []).map((m) => ({
    user_id: m.user_id as string,
    league_id: m.league_id as string,
    league_name:
      ((m.league as { name?: string } | null)?.name ?? "Lig") as string,
  }));
  if (pairs.length === 0) return [];

  const { data: predicted, error: predErr } = await c
    .from("predictions")
    .select("user_id, league_id")
    .eq("race_id", raceId);
  if (predErr) throw predErr;
  const predictedSet = new Set(
    (predicted ?? []).map((r) => `${r.user_id}:${r.league_id}`),
  );

  const { data: alreadySent, error: sentErr } = await c
    .from("notifications_log")
    .select("user_id, league_id")
    .eq("race_id", raceId)
    .eq("kind", kind)
    .eq("channel", "email");
  if (sentErr) throw sentErr;
  const sentSet = new Set(
    (alreadySent ?? []).map((r) => `${r.user_id}:${r.league_id}`),
  );

  const targets = pairs.filter((p) =>
    !predictedSet.has(`${p.user_id}:${p.league_id}`) &&
    !sentSet.has(`${p.user_id}:${p.league_id}`)
  );
  if (targets.length === 0) return [];

  const { data: profiles } = await c
    .from("profiles")
    .select("id, username")
    .in("id", Array.from(new Set(targets.map((t) => t.user_id))));
  if (!profiles || profiles.length === 0) return [];
  const profileMap = new Map(
    profiles.map((p) => [p.id as string, p.username as string]),
  );

  // auth.users email'lerini RPC ile (admin API yerine) çek
  const { data: emailRows, error: emailErr } = await c.rpc("get_user_emails", {
    p_ids: Array.from(new Set(targets.map((t) => t.user_id))),
  });
  if (emailErr) throw emailErr;
  const emailMap = new Map<string, string>(
    (emailRows ?? []).map((
      r: { id: string; email: string },
    ) => [r.id, r.email]),
  );

  const result: UserToRemind[] = [];
  for (const target of targets) {
    const email = emailMap.get(target.user_id);
    if (email) {
      result.push({
        id: target.user_id,
        email,
        username: profileMap.get(target.user_id) ?? "Pilot",
        league_id: target.league_id,
        league_name: target.league_name,
      });
    }
  }
  return result;
}

async function processRace(
  c: SupabaseClient,
  race: RaceRow,
  kind: "reminder_6h" | "reminder_1h",
  fromAddr: string,
  resendKey: string | undefined,
  counters: { sent: number; skipped: number; errors: number },
) {
  const users = await findUsersMissingPrediction(c, race.id, kind);
  for (const u of users) {
    try {
      if (resendKey) {
        await sendEmail(resendKey, fromAddr, u, race, kind);
      }
      const { error } = await c.from("notifications_log").insert({
        user_id: u.id,
        race_id: race.id,
        league_id: u.league_id,
        kind,
        channel: "email",
      });
      if (error) {
        // Duplicate insert (UNIQUE) → başkası gönderdi sayılır, atla.
        if (error.code === "23505") {
          counters.skipped++;
        } else {
          counters.errors++;
        }
      } else {
        counters.sent++;
      }
    } catch (_e) {
      counters.errors++;
    }
  }
}

async function sendEmail(
  apiKey: string,
  from: string,
  user: UserToRemind,
  race: RaceRow,
  kind: "reminder_6h" | "reminder_1h",
) {
  const minsLeft = kind === "reminder_1h" ? "1 saat" : "6 saat";
  const subject = `${race.name} — tahminin için son ${minsLeft}`;
  const body = `
    <p>Merhaba ${user.username},</p>
    <p><b>${user.league_name}</b> liginde <b>${race.name}</b> için tahminlerin kilide kadar yaklaşık ${minsLeft} kaldı.</p>
    <p>Uygulamayı aç ve seçimlerini yap — kilit zamanı: ${race.lock_at}.</p>
    <p>— GridCall</p>
  `.trim();

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [user.email],
      subject,
      html: body,
    }),
  });
  if (!res.ok) {
    throw new Error(`Resend HTTP ${res.status}: ${await res.text()}`);
  }
}

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
