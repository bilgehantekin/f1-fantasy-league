// OpenF1'den yarış sonuçlarını çekip race_results tablosuna yazar.
// Trigger zinciri (handle_race_result -> score_race) tüm tahminleri otomatik puanlar.
//
// Çağırma şekilleri:
//   POST /ingest-openf1                      → son 24 saat içinde biten ve sonucu olmayan yarışlar
//   POST /ingest-openf1 {"race_id":"<uuid>"} → tek yarış
//   POST /ingest-openf1 {"race_id":"...","dry_run":true} → DB'ye yazmaz, payload döner
//
// Cron örneği (pg_cron): yarış günü saatte bir
//   select cron.schedule('ingest-openf1','*/30 * * * *',
//     $$select net.http_post(url:='<edge-fn-url>', headers:='{"Authorization":"Bearer <key>"}', body:='{}')$$);

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const OPENF1 = "https://api.openf1.org/v1";
const TWO_WEEKS_MS = 14 * 24 * 3600 * 1000;

interface OpenF1Meeting {
  meeting_key: number;
  meeting_name: string;
  date_start: string;
  year: number;
}
interface OpenF1Session {
  session_key: number;
  session_type: string;
  date_start: string;
}
interface OpenF1Result {
  position: number | null;
  driver_number: number;
  dnf: boolean;
  dns: boolean;
  dsq: boolean;
}
interface OpenF1Lap {
  driver_number: number;
  lap_duration: number | null;
  is_pit_out_lap: boolean;
}

interface IngestBody {
  race_id?: string;
  dry_run?: boolean;
  mode?: "results" | "season-bootstrap";
  year?: number;
}

interface OpenF1Driver {
  driver_number: number;
  name_acronym: string;
  full_name: string;
  team_name: string | null;
  team_colour: string | null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let body: IngestBody = {};
  if (req.method === "POST") {
    try {
      body = await req.json();
    } catch {
      // body opsiyonel
    }
  }

  const c = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (body.mode === "season-bootstrap") {
    const year = body.year ?? new Date().getFullYear();
    return jsonResponse(await bootstrapSeason(c, year));
  }

  const raceIds = await resolveRaceIds(c, body.race_id);
  const results: unknown[] = [];
  for (const id of raceIds) {
    try {
      results.push(await ingestRace(c, id, body.dry_run ?? false));
    } catch (e) {
      results.push({ race_id: id, error: String(e) });
    }
  }

  return jsonResponse({ count: results.length, results });
});

async function resolveRaceIds(
  c: SupabaseClient,
  explicitId: string | undefined,
): Promise<string[]> {
  if (explicitId) return [explicitId];

  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const now = new Date().toISOString();
  const { data: races } = await c
    .from("races")
    .select("id")
    .lte("race_at", now)
    .gte("race_at", since);
  const { data: existing } = await c.from("race_results").select("race_id");
  const have = new Set((existing ?? []).map((r) => r.race_id as string));
  return (races ?? []).map((r) => r.id as string).filter((id) => !have.has(id));
}

async function ingestRace(
  c: SupabaseClient,
  raceId: string,
  dryRun: boolean,
) {
  const { data: race, error } = await c
    .from("races")
    .select("*")
    .eq("id", raceId)
    .single();
  if (error || !race) throw new Error(`race not found: ${raceId}`);

  const meeting = await findMeeting(race.season_id, new Date(race.race_at));
  if (!meeting) throw new Error("OpenF1 meeting not found within 14 days");

  // OpenF1 rate-limit'ten kaçınmak için sıralı çağrı.
  const raceSession = await findSession(meeting.meeting_key, "Race");
  if (!raceSession) throw new Error("Race session not found");
  const qualSession = await findSession(meeting.meeting_key, "Qualifying");

  const raceResults = await fetchJson<OpenF1Result[]>(
    `${OPENF1}/session_result?session_key=${raceSession.session_key}`,
  );
  const qualResults: OpenF1Result[] = qualSession
    ? await fetchJson<OpenF1Result[]>(
        `${OPENF1}/session_result?session_key=${qualSession.session_key}`,
      )
    : [];
  const fastestLap = await findFastestLap(raceSession.session_key);

  const { data: drivers } = await c
    .from("drivers")
    .select("id, number, code")
    .eq("season_id", race.season_id);
  const byNumber = new Map<number, { id: string; code: string }>();
  for (const d of drivers ?? []) {
    if (d.number != null) byNumber.set(d.number as number, d);
  }

  const sortedRace = raceResults
    .filter((r) => r.position != null)
    .sort((a, b) => (a.position ?? 0) - (b.position ?? 0));
  const sortedQual = qualResults
    .filter((r) => r.position != null)
    .sort((a, b) => (a.position ?? 0) - (b.position ?? 0));

  const p1 = byNumber.get(sortedRace[0]?.driver_number);
  const p2 = byNumber.get(sortedRace[1]?.driver_number);
  const p3 = byNumber.get(sortedRace[2]?.driver_number);
  const pole = byNumber.get(sortedQual[0]?.driver_number);
  const fl = fastestLap ? byNumber.get(fastestLap.driver_number) : undefined;
  const dnfCount = raceResults.filter((r) => r.dnf || r.dns || r.dsq).length;

  const missing: string[] = [];
  if (!p1) missing.push(`p1#${sortedRace[0]?.driver_number}`);
  if (!p2) missing.push(`p2#${sortedRace[1]?.driver_number}`);
  if (!p3) missing.push(`p3#${sortedRace[2]?.driver_number}`);
  if (!pole) missing.push(`pole#${sortedQual[0]?.driver_number}`);
  if (!fl) missing.push(`fl#${fastestLap?.driver_number}`);

  const payload = {
    race_id: raceId,
    p1: p1?.id,
    p2: p2?.id,
    p3: p3?.id,
    pole: pole?.id,
    fastest_lap: fl?.id,
    dnf_count: dnfCount,
  };

  if (missing.length > 0) {
    return {
      race_id: raceId,
      error: "missing driver mapping",
      missing,
      meeting_key: meeting.meeting_key,
      payload,
    };
  }
  if (dryRun) {
    return {
      race_id: raceId,
      dry_run: true,
      meeting: meeting.meeting_name,
      payload,
    };
  }

  const { error: upErr } = await c.from("race_results").upsert(payload);
  if (upErr) throw upErr;

  return {
    race_id: raceId,
    ok: true,
    meeting: meeting.meeting_name,
    dnf_count: dnfCount,
  };
}

async function findMeeting(year: number, raceAt: Date): Promise<OpenF1Meeting | null> {
  const meetings = await fetchJson<OpenF1Meeting[]>(
    `${OPENF1}/meetings?year=${year}`,
  );
  let best: OpenF1Meeting | null = null;
  let bestDelta = Infinity;
  const target = raceAt.getTime();
  for (const m of meetings) {
    if (!m.date_start) continue;
    const delta = Math.abs(new Date(m.date_start).getTime() - target);
    if (delta < bestDelta && delta < TWO_WEEKS_MS) {
      bestDelta = delta;
      best = m;
    }
  }
  return best;
}

async function findSession(
  meetingKey: number,
  sessionType: string,
): Promise<OpenF1Session | null> {
  const sessions = await fetchJson<OpenF1Session[]>(
    `${OPENF1}/sessions?meeting_key=${meetingKey}&session_type=${sessionType}`,
  );
  return sessions[0] ?? null;
}

async function findFastestLap(sessionKey: number): Promise<OpenF1Lap | null> {
  const laps = await fetchJson<OpenF1Lap[]>(
    `${OPENF1}/laps?session_key=${sessionKey}`,
  );
  let best: OpenF1Lap | null = null;
  let bestTime = Infinity;
  for (const l of laps) {
    if (
      l.lap_duration != null &&
      l.lap_duration > 0 &&
      !l.is_pit_out_lap &&
      l.lap_duration < bestTime
    ) {
      bestTime = l.lap_duration;
      best = l;
    }
  }
  return best;
}

async function fetchJson<T>(url: string): Promise<T> {
  // 429 / 503 → backoff ile 3 deneme
  let attempt = 0;
  while (true) {
    const res = await fetch(url);
    if (res.ok) return (await res.json()) as T;
    if ((res.status === 429 || res.status === 503) && attempt < 5) {
      const delay = 2000 * Math.pow(2, attempt);
      await new Promise((r) => setTimeout(r, delay));
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

// ---------- Season bootstrap ----------

function teamCode(name: string): string {
  // OpenF1 takım adı → kısa kod (3 harf)
  const map: Record<string, string> = {
    "McLaren": "MCL",
    "Ferrari": "FER",
    "Mercedes": "MER",
    "Red Bull Racing": "RBR",
    "Aston Martin": "AST",
    "Alpine": "ALP",
    "Williams": "WIL",
    "Audi": "AUD",
    "Racing Bulls": "RB",
    "RB": "RB",
    "Haas F1 Team": "HAA",
    "Haas": "HAA",
    "Cadillac": "CAD",
    "Sauber": "SAU",
    "Kick Sauber": "SAU",
    "AlphaTauri": "AT",
  };
  if (map[name]) return map[name];
  return name.replace(/[^A-Z]/g, "").slice(0, 3).padEnd(3, "X").toUpperCase();
}

async function bootstrapSeason(c: SupabaseClient, year: number) {
  // 1) Sezon
  const { error: seasonErr } = await c
    .from("seasons")
    .upsert({ id: year, is_active: true });
  if (seasonErr) throw seasonErr;

  // 2) Sürücü ve takımlar (latest session)
  const drivers = await fetchJson<OpenF1Driver[]>(
    `${OPENF1}/drivers?session_key=latest`,
  );

  // Takımlar: ad → kod
  const teamRows = new Map<
    string,
    { season_id: number; code: string; name: string; color: string | null }
  >();
  for (const d of drivers) {
    if (!d.team_name) continue;
    const code = teamCode(d.team_name);
    if (!teamRows.has(code)) {
      teamRows.set(code, {
        season_id: year,
        code,
        name: d.team_name,
        color: d.team_colour ? "#" + d.team_colour : null,
      });
    }
  }
  const { error: teamErr } = await c
    .from("teams")
    .upsert(Array.from(teamRows.values()), { onConflict: "season_id,code" });
  if (teamErr) throw teamErr;

  // Yeniden çek (id'leri al)
  const { data: teamsRows } = await c
    .from("teams")
    .select("id, code")
    .eq("season_id", year);
  const teamIdByCode = new Map<string, string>(
    (teamsRows ?? []).map((t) => [t.code as string, t.id as string]),
  );

  // Sürücüler
  const driverRows = drivers.map((d) => ({
    season_id: year,
    code: d.name_acronym,
    full_name: d.full_name,
    number: d.driver_number,
    team_id: d.team_name ? teamIdByCode.get(teamCode(d.team_name)) : null,
  }));
  const { error: drvErr } = await c
    .from("drivers")
    .upsert(driverRows, { onConflict: "season_id,code" });
  if (drvErr) throw drvErr;

  // 3) Yarış takvimi
  type Meeting = {
    meeting_key: number;
    meeting_name: string;
    location: string;
    date_start: string;
    year: number;
  };
  const allMeetings = await fetchJson<Meeting[]>(
    `${OPENF1}/meetings?year=${year}`,
  );
  const meetings = allMeetings
    .filter((m) => !/Testing/i.test(m.meeting_name))
    .sort((a, b) => a.date_start.localeCompare(b.date_start));

  let raceCount = 0;
  for (let i = 0; i < meetings.length; i++) {
    const m = meetings[i];
    // Rate-limit'e karşı her iterasyondan önce 400ms bekle
    if (i > 0) await new Promise((r) => setTimeout(r, 400));
    const raceSession = await findSession(m.meeting_key, "Race");
    await new Promise((r) => setTimeout(r, 200));
    const qualSession = await findSession(m.meeting_key, "Qualifying");
    const raceAt = raceSession?.date_start ?? m.date_start;
    // Qualifying genelde yarıştan 1 gün önce; OpenF1 vermezse yedek
    const qualAt = qualSession?.date_start ??
      new Date(new Date(raceAt).getTime() - 24 * 3600 * 1000).toISOString();

    const { error: rErr } = await c.from("races").upsert(
      {
        season_id: year,
        round: i + 1,
        name: m.meeting_name,
        circuit: m.location,
        qualifying_at: qualAt,
        race_at: raceAt,
      },
      { onConflict: "season_id,round" },
    );
    if (rErr) throw rErr;
    raceCount++;
  }

  return {
    year,
    teams: teamRows.size,
    drivers: driverRows.length,
    races: raceCount,
  };
}
