// Canlı yarış pozisyonlarını OpenF1'den çekip live_positions tablosuna yazar.
// Realtime publication üzerinden Flutter client'a anlık yansır.
//
// Çağırma:
//   POST /live-positions {"race_id":"<uuid>"}
//   POST /live-positions   (body yok → status='live' olan tüm yarışları işler)
//
// Replay testi (geçmiş yarış üzerinden):
//   POST /live-positions {
//     "race_id":"<uuid>",
//     "replay_session_key": 9693,
//     "replay_until": "2025-03-16T05:30:00Z"
//   }
//
// Cron örneği (yarış sırasında 10sn'de bir):
//   select cron.schedule('live-positions','*/10 * * * * *', $$select net.http_post(...)$$);

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const OPENF1 = "https://api.openf1.org/v1";

interface Body {
  race_id?: string;
  replay_session_key?: number;
  replay_until?: string;
}

interface PositionEntry {
  date: string;
  driver_number: number;
  position: number | null;
  session_key: number;
}

interface SessionRow {
  meeting_key: number;
  session_key: number;
  date_start: string;
}

interface MeetingRow {
  meeting_key: number;
  date_start: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let body: Body = {};
  if (req.method === "POST") {
    try {
      body = await req.json();
    } catch {
      // boş body OK
    }
  }

  const c = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let raceIds: string[] = [];
  if (body.race_id) {
    raceIds = [body.race_id];
  } else {
    const { data } = await c
      .from("races")
      .select("id")
      .eq("status", "live");
    raceIds = (data ?? []).map((r) => r.id as string);
  }

  const results: unknown[] = [];
  for (const raceId of raceIds) {
    try {
      results.push(
        await ingestPositions(c, raceId, body.replay_session_key, body.replay_until),
      );
    } catch (e) {
      results.push({ race_id: raceId, error: String(e) });
    }
  }

  return jsonResponse({ count: results.length, results });
});

async function ingestPositions(
  c: SupabaseClient,
  raceId: string,
  replaySessionKey: number | undefined,
  replayUntil: string | undefined,
) {
  const { data: race, error } = await c
    .from("races")
    .select("season_id, race_at, name")
    .eq("id", raceId)
    .single();
  if (error || !race) throw new Error(`race not found: ${raceId}`);

  // Session_key tespiti: replay varsa kullan, yoksa OpenF1'den bul
  let sessionKey: number;
  if (replaySessionKey != null) {
    sessionKey = replaySessionKey;
  } else {
    const meeting = await findMeetingByDate(race.season_id, new Date(race.race_at));
    if (!meeting) throw new Error("OpenF1 meeting not found");
    const session = await findSession(meeting.meeting_key, "Race");
    if (!session) throw new Error("Race session not found");
    sessionKey = session.session_key;
  }

  // Pozisyon kayıtları çek
  let url = `${OPENF1}/position?session_key=${sessionKey}`;
  if (replayUntil) url += `&date<=${replayUntil}`;
  const positions = await fetchJson<PositionEntry[]>(url);

  if (positions.length === 0) {
    return { race_id: raceId, session_key: sessionKey, updated: 0 };
  }

  // Her sürücü için en son pozisyonu al
  const latestByDriver = new Map<number, PositionEntry>();
  for (const p of positions) {
    const existing = latestByDriver.get(p.driver_number);
    if (!existing || p.date > existing.date) {
      latestByDriver.set(p.driver_number, p);
    }
  }

  // Driver mapping (sezon bazlı)
  const { data: drivers } = await c
    .from("drivers")
    .select("id, number")
    .eq("season_id", race.season_id);
  const driverIdByNumber = new Map<number, string>();
  for (const d of drivers ?? []) {
    if (d.number != null) driverIdByNumber.set(d.number as number, d.id as string);
  }

  // Upsert payload
  const rows: {
    race_id: string;
    driver_id: string;
    position: number | null;
    status: string;
    updated_at: string;
  }[] = [];
  for (const [num, p] of latestByDriver) {
    const driverId = driverIdByNumber.get(num);
    if (!driverId) continue;
    rows.push({
      race_id: raceId,
      driver_id: driverId,
      position: p.position,
      status: p.position == null ? "retired" : "running",
      updated_at: p.date,
    });
  }

  if (rows.length > 0) {
    const { error: upErr } = await c
      .from("live_positions")
      .upsert(rows, { onConflict: "race_id,driver_id" });
    if (upErr) throw upErr;
  }

  return {
    race_id: raceId,
    session_key: sessionKey,
    updated: rows.length,
    sample_top3: rows
      .filter((r) => r.position != null && r.position <= 3)
      .sort((a, b) => (a.position ?? 0) - (b.position ?? 0)),
  };
}

async function findMeetingByDate(year: number, raceAt: Date) {
  const meetings = await fetchJson<MeetingRow[]>(
    `${OPENF1}/meetings?year=${year}`,
  );
  let best: MeetingRow | null = null;
  let bestDelta = Infinity;
  const target = raceAt.getTime();
  for (const m of meetings) {
    if (!m.date_start) continue;
    const delta = Math.abs(new Date(m.date_start).getTime() - target);
    if (delta < bestDelta && delta < 14 * 24 * 3600 * 1000) {
      bestDelta = delta;
      best = m;
    }
  }
  return best;
}

async function findSession(meetingKey: number, sessionType: string) {
  const sessions = await fetchJson<SessionRow[]>(
    `${OPENF1}/sessions?meeting_key=${meetingKey}&session_type=${sessionType}`,
  );
  return sessions[0] ?? null;
}

async function fetchJson<T>(url: string): Promise<T> {
  let attempt = 0;
  while (true) {
    const res = await fetch(url);
    if (res.ok) return (await res.json()) as T;
    if ((res.status === 429 || res.status === 503) && attempt < 3) {
      await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
      attempt++;
      continue;
    }
    throw new Error(`HTTP ${res.status} ${url}`);
  }
}

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
