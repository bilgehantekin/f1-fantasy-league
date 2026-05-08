// OpenF1'den yarış sonuçlarını çekip race_results tablosuna yazar.
// Trigger zinciri (handle_race_result -> score_race) tüm tahminleri otomatik puanlar.
//
// Çağırma şekilleri:
//   POST /ingest-openf1                      → son 72 saatte biten yarışları yeniden/idempotent çeker
//   POST /ingest-openf1 {"audit":true}       → son 7 günde biten yarışları yeniden kontrol eder
//   POST /ingest-openf1 {"race_id":"<uuid>"} → tek yarış
//   POST /ingest-openf1 {"race_id":"...","dry_run":true} → DB'ye yazmaz, payload döner
//   POST /ingest-openf1 {"race_id":"...","force_sprint":false} → mevcut sprint sonucunu korur
//
// Cron: 0021_schedule_openf1_ingest.sql migration'ı pg_cron + pg_net ile bağlar.

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const OPENF1 = "https://api.openf1.org/v1";
const TWO_WEEKS_MS = 14 * 24 * 3600 * 1000;
const AUTO_REINGEST_WINDOW_MS = 72 * 3600 * 1000;
const POST_RACE_AUDIT_WINDOW_MS = 7 * 24 * 3600 * 1000;

interface OpenF1Meeting {
  meeting_key: number;
  meeting_name: string;
  date_start: string;
  year: number;
}
interface OpenF1Session {
  session_key: number;
  session_name?: string;
  session_type: string;
  date_start: string;
  date_end?: string | null;
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
interface OpenF1RaceControl {
  category: string | null;
  flag: string | null;
  message: string | null;
}

interface IngestBody {
  race_id?: string;
  dry_run?: boolean;
  force_sprint?: boolean;
  audit?: boolean;
  mode?: "results" | "season-bootstrap" | "sync-sessions";
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

  if (body.mode === "sync-sessions") {
    const year = body.year ?? new Date().getFullYear();
    return jsonResponse(await syncSeasonSessions(c, year));
  }

  const raceIds = await resolveRaceIds(c, body.race_id, body.audit ?? false);
  const refreshSprint = body.force_sprint ?? true;
  const results: unknown[] = [];
  for (const id of raceIds) {
    try {
      results.push(
        await ingestRace(
          c,
          id,
          body.dry_run ?? false,
          refreshSprint,
        ),
      );
    } catch (e) {
      results.push({ race_id: id, error: String(e) });
    }
  }

  return jsonResponse({ count: results.length, results });
});

async function resolveRaceIds(
  c: SupabaseClient,
  explicitId: string | undefined,
  audit: boolean,
): Promise<string[]> {
  if (explicitId) return [explicitId];

  const windowMs = audit ? POST_RACE_AUDIT_WINDOW_MS : AUTO_REINGEST_WINDOW_MS;
  const since = new Date(Date.now() - windowMs).toISOString();
  const now = new Date().toISOString();
  const { data: races } = await c
    .from("races")
    .select("id")
    .lte("race_at", now)
    .gte("race_at", since)
    .order("race_at", { ascending: true });
  return (races ?? []).map((r) => r.id as string);
}

async function ingestRace(
  c: SupabaseClient,
  raceId: string,
  dryRun: boolean,
  forceSprint: boolean,
) {
  const { data: race, error } = await c
    .from("races")
    .select("*")
    .eq("id", raceId)
    .single();
  if (error || !race) throw new Error(`race not found: ${raceId}`);

  const meeting = await findMeeting(race.season_id, new Date(race.race_at));
  if (!meeting) throw new Error("OpenF1 meeting not found within 14 days");

  // Sprint weekend kontrolü
  const { sprintQuali, sprintRace } = await findSprintSessions(
    meeting.meeting_key,
  );
  const hasSprint = !!(sprintQuali && sprintRace);

  // Ana yarış sessions (sprint adlarını filtreliyor)
  const { mainQuali, mainRace } = await findMainQualifyingAndRace(
    meeting.meeting_key,
  );
  const raceSession = mainRace ??
    await findSession(meeting.meeting_key, "Race");
  if (!raceSession) throw new Error("Race session not found");
  await syncRaceSessions(c, raceId, meeting.meeting_key);
  const qualSession = mainQuali ??
    await findSession(meeting.meeting_key, "Qualifying");

  const raceResults = await fetchJson<OpenF1Result[]>(
    `${OPENF1}/session_result?session_key=${raceSession.session_key}`,
  );
  const qualResults: OpenF1Result[] = qualSession
    ? await fetchJson<OpenF1Result[]>(
      `${OPENF1}/session_result?session_key=${qualSession.session_key}`,
    )
    : [];
  const fastestLap = await findFastestLap(raceSession.session_key);
  const raceControl = await fetchJson<OpenF1RaceControl[]>(
    `${OPENF1}/race_control?session_key=${raceSession.session_key}`,
  );

  const { data: drivers } = await c
    .from("drivers")
    .select("id, number, code, team_id")
    .eq("season_id", race.season_id);
  const byNumber = new Map<
    number,
    { id: string; code: string; team_id: string | null }
  >();
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
  const dnfCount = countDnfResults(raceResults);
  const topTeamId = topScoringTeamId(sortedRace, byNumber, mainPoints());
  const safetyCar = hasSafetyCar(raceControl);

  // Tam klasman: her sürücü için satır (DNF/DSQ/DNS dahil).
  const classification = raceResults
    .map((r) => {
      const drv = byNumber.get(r.driver_number);
      if (!drv) return null;
      const status = r.dsq ? "dsq" : r.dns ? "dns" : r.dnf ? "dnf" : "finished";
      return {
        race_id: raceId,
        driver_id: drv.id,
        position: r.position ?? null,
        status,
      };
    })
    .filter((x): x is NonNullable<typeof x> => x !== null);

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
    top_team_id: topTeamId,
    safety_car: safetyCar,
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
  // ---- Sprint sonuçları (sprint weekend ise) ----
  let sprintPayload: {
    race_id: string;
    p1: string;
    p2: string;
    p3: string;
    pole: string;
    dnf_count: number;
    top_team_id: string | null;
    safety_car: boolean;
  } | null = null;
  let sprintClassification: Array<{
    race_id: string;
    driver_id: string;
    position: number | null;
    status: string;
  }> = [];
  let sprintMissing: string[] = [];

  if (hasSprint && sprintRace && sprintQuali) {
    const sprintResults = await fetchJson<OpenF1Result[]>(
      `${OPENF1}/session_result?session_key=${sprintRace.session_key}`,
    );
    const sprintQualResults = await fetchJson<OpenF1Result[]>(
      `${OPENF1}/session_result?session_key=${sprintQuali.session_key}`,
    );
    const sprintRaceControl = await fetchJson<OpenF1RaceControl[]>(
      `${OPENF1}/race_control?session_key=${sprintRace.session_key}`,
    );
    const sprintRaceSorted = sprintResults
      .filter((r) => r.position != null)
      .sort((a, b) => (a.position ?? 0) - (b.position ?? 0));
    const sprintQualSorted = sprintQualResults
      .filter((r) => r.position != null)
      .sort((a, b) => (a.position ?? 0) - (b.position ?? 0));

    const sp1 = byNumber.get(sprintRaceSorted[0]?.driver_number);
    const sp2 = byNumber.get(sprintRaceSorted[1]?.driver_number);
    const sp3 = byNumber.get(sprintRaceSorted[2]?.driver_number);
    const sPole = byNumber.get(sprintQualSorted[0]?.driver_number);
    const sDnfCount = countDnfResults(sprintResults);
    const sTopTeamId = topScoringTeamId(
      sprintRaceSorted,
      byNumber,
      sprintPoints(),
    );
    const sSafetyCar = hasSafetyCar(sprintRaceControl);

    if (!sp1) sprintMissing.push(`sp1#${sprintRaceSorted[0]?.driver_number}`);
    if (!sp2) sprintMissing.push(`sp2#${sprintRaceSorted[1]?.driver_number}`);
    if (!sp3) sprintMissing.push(`sp3#${sprintRaceSorted[2]?.driver_number}`);
    if (!sPole) {
      sprintMissing.push(`sprint_pole#${sprintQualSorted[0]?.driver_number}`);
    }

    if (sp1 && sp2 && sp3 && sPole) {
      sprintPayload = {
        race_id: raceId,
        p1: sp1.id,
        p2: sp2.id,
        p3: sp3.id,
        pole: sPole.id,
        dnf_count: sDnfCount,
        top_team_id: sTopTeamId,
        safety_car: sSafetyCar,
      };
    }

    sprintClassification = sprintResults
      .map((r) => {
        const drv = byNumber.get(r.driver_number);
        if (!drv) return null;
        const status = r.dsq
          ? "dsq"
          : r.dns
          ? "dns"
          : r.dnf
          ? "dnf"
          : "finished";
        return {
          race_id: raceId,
          driver_id: drv.id,
          position: r.position ?? null,
          status,
        };
      })
      .filter((x): x is NonNullable<typeof x> => x !== null);
  }

  if (dryRun) {
    return {
      race_id: raceId,
      dry_run: true,
      meeting: meeting.meeting_name,
      payload,
      classification_rows: classification.length,
      has_sprint: hasSprint,
      sprint_payload: sprintPayload,
      sprint_classification_rows: sprintClassification.length,
      sprint_missing: sprintMissing,
    };
  }

  const { error: upErr } = await c.from("race_results").upsert(payload);
  if (upErr) throw upErr;

  // Eski klasman satırlarını temizle, yenisini yaz (idempotent re-ingest).
  const { error: delErr } = await c
    .from("race_classifications")
    .delete()
    .eq("race_id", raceId);
  if (delErr) throw delErr;
  if (classification.length > 0) {
    const { error: clsErr } = await c
      .from("race_classifications")
      .insert(classification);
    if (clsErr) throw clsErr;
  }

  const { data: existingSprint } = await c
    .from("sprint_results")
    .select("race_id")
    .eq("race_id", raceId)
    .maybeSingle();
  const sprintToWrite = sprintPayload;
  const shouldWriteSprint = !!sprintToWrite && (!existingSprint || forceSprint);

  // Sprint sonuçları da yeniden yazılır; yarış sonrası cezalar ve klasman
  // düzeltmeleri sprint puanlarına da yansısın. Gerekirse çağıran taraf
  // force_sprint:false göndererek mevcut sprint sonucunu koruyabilir.
  if (shouldWriteSprint && sprintToWrite) {
    const { error: spErr } = await c.from("sprint_results").upsert(
      sprintToWrite,
    );
    if (spErr) throw spErr;
  }
  if (hasSprint && (!existingSprint || forceSprint)) {
    await c.from("sprint_classifications").delete().eq("race_id", raceId);
    if (sprintClassification.length > 0) {
      const { error: scErr } = await c
        .from("sprint_classifications")
        .insert(sprintClassification);
      if (scErr) throw scErr;
    }
  }

  return {
    race_id: raceId,
    ok: true,
    meeting: meeting.meeting_name,
    dnf_count: dnfCount,
    classification_rows: classification.length,
    sprint_ingested: shouldWriteSprint,
    sprint_skipped_existing: !!sprintPayload && !!existingSprint &&
      !forceSprint,
    sprint_classification_rows: shouldWriteSprint
      ? sprintClassification.length
      : 0,
    sprint_missing: sprintMissing,
  };
}

async function findMeeting(
  year: number,
  raceAt: Date,
): Promise<OpenF1Meeting | null> {
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

// Sprint weekend tespit: aynı meeting içinde Sprint / Sprint Qualifying var mı?
async function findSprintSessions(
  meetingKey: number,
): Promise<
  { sprintQuali: OpenF1Session | null; sprintRace: OpenF1Session | null }
> {
  const all = await fetchJson<(OpenF1Session & { session_name?: string })[]>(
    `${OPENF1}/sessions?meeting_key=${meetingKey}`,
  );
  const byName = (re: RegExp) =>
    all.find((s) =>
      re.test(s.session_name ?? "") || re.test(s.session_type ?? "")
    ) ?? null;
  return {
    sprintQuali: byName(/Sprint\s*(Qualifying|Shootout)/i),
    sprintRace: byName(/^Sprint$/i) ?? byName(/Sprint\s*Race/i),
  };
}

// Ana yarış sessions: sprint weekend'de "Qualifying" ve "Race" sessionları
// Sprint Qualifying / Sprint Race ile karışmasın diye name filtresi.
async function findMainQualifyingAndRace(meetingKey: number): Promise<{
  mainQuali: OpenF1Session | null;
  mainRace: OpenF1Session | null;
}> {
  const all = await fetchJson<(OpenF1Session & { session_name?: string })[]>(
    `${OPENF1}/sessions?meeting_key=${meetingKey}`,
  );
  const isSprintNamed = (s: OpenF1Session & { session_name?: string }) =>
    /sprint/i.test(s.session_name ?? "");
  const mainQuali = all.find(
    (s) => s.session_type === "Qualifying" && !isSprintNamed(s),
  ) ?? null;
  const mainRace =
    all.find((s) => s.session_type === "Race" && !isSprintNamed(s)) ?? null;
  return { mainQuali, mainRace };
}

async function syncRaceSessions(
  c: SupabaseClient,
  raceId: string,
  meetingKey: number,
) {
  const all = await fetchJson<OpenF1Session[]>(
    `${OPENF1}/sessions?meeting_key=${meetingKey}`,
  );
  const sessions = all
    .map((session) => canonicalSession(session))
    .filter((session): session is NonNullable<typeof session> =>
      session !== null
    )
    .sort((a, b) => a.sort_order - b.sort_order);

  if (sessions.length === 0) return;

  const rows = sessions.map((session) => ({
    race_id: raceId,
    session_key: session.session_key,
    session_name: session.session_name,
    session_type: session.session_type,
    short_label: session.short_label,
    sort_order: session.sort_order,
    starts_at: session.starts_at,
    ends_at: session.ends_at,
    source: "openf1",
    updated_at: new Date().toISOString(),
  }));

  const { error } = await c
    .from("race_sessions")
    .upsert(rows, { onConflict: "race_id,short_label" });
  if (error) throw error;
}

function canonicalSession(session: OpenF1Session): {
  session_key: number;
  session_name: string;
  session_type: string;
  short_label: string;
  sort_order: number;
  starts_at: string;
  ends_at: string | null;
} | null {
  const name = session.session_name ?? session.session_type;
  const type = session.session_type;
  const normalized = `${name} ${type}`.toLowerCase();

  let shortLabel: string | null = null;
  let sortOrder: number | null = null;

  if (/practice\s*1|free practice\s*1|fp1/.test(normalized)) {
    shortLabel = "P1";
    sortOrder = 10;
  } else if (/practice\s*2|free practice\s*2|fp2/.test(normalized)) {
    shortLabel = "P2";
    sortOrder = 20;
  } else if (/practice\s*3|free practice\s*3|fp3/.test(normalized)) {
    shortLabel = "P3";
    sortOrder = 30;
  } else if (/sprint.*(qualifying|shootout)/.test(normalized)) {
    shortLabel = "SQ";
    sortOrder = 20;
  } else if (/^sprint$|sprint race/.test(name.toLowerCase())) {
    shortLabel = "SR";
    sortOrder = 30;
  } else if (type === "Qualifying" && !/sprint/.test(normalized)) {
    shortLabel = "Q";
    sortOrder = 40;
  } else if (type === "Race" && !/sprint/.test(normalized)) {
    shortLabel = "R";
    sortOrder = 50;
  }

  if (shortLabel == null || sortOrder == null || !session.date_start) {
    return null;
  }

  return {
    session_key: session.session_key,
    session_name: name,
    session_type: type,
    short_label: shortLabel,
    sort_order: sortOrder,
    starts_at: session.date_start,
    ends_at: session.date_end ?? null,
  };
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

function countDnfResults(results: OpenF1Result[]): number {
  return results.filter((r) => r.dnf && !r.dns && !r.dsq).length;
}

function topScoringTeamId(
  sortedRace: OpenF1Result[],
  byNumber: Map<number, { id: string; code: string; team_id: string | null }>,
  pointsByPosition: Map<number, number>,
): string | null {
  const teamPoints = new Map<string, number>();
  for (const result of sortedRace) {
    if (result.position == null) continue;
    const points = pointsByPosition.get(result.position) ?? 0;
    if (points === 0) continue;
    const teamId = byNumber.get(result.driver_number)?.team_id;
    if (!teamId) continue;
    teamPoints.set(teamId, (teamPoints.get(teamId) ?? 0) + points);
  }
  let bestTeamId: string | null = null;
  let bestPoints = -1;
  for (const [teamId, points] of teamPoints.entries()) {
    if (points > bestPoints) {
      bestTeamId = teamId;
      bestPoints = points;
    }
  }
  return bestTeamId;
}

function mainPoints(): Map<number, number> {
  return new Map<number, number>([
    [1, 25],
    [2, 18],
    [3, 15],
    [4, 12],
    [5, 10],
    [6, 8],
    [7, 6],
    [8, 4],
    [9, 2],
    [10, 1],
  ]);
}

function sprintPoints(): Map<number, number> {
  return new Map<number, number>([
    [1, 8],
    [2, 7],
    [3, 6],
    [4, 5],
    [5, 4],
    [6, 3],
    [7, 2],
    [8, 1],
  ]);
}

function hasSafetyCar(events: OpenF1RaceControl[]): boolean {
  return events.some((event) => {
    const category = (event.category ?? "").toUpperCase();
    const message = (event.message ?? "").toUpperCase();
    return category.includes("SAFETY") ||
      message.includes("SAFETY CAR") ||
      message.includes("VIRTUAL SAFETY CAR");
  });
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
    "Sauber": "AUD",
    "Kick Sauber": "AUD",
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
  let sprintCount = 0;
  for (let i = 0; i < meetings.length; i++) {
    const m = meetings[i];
    if (i > 0) await new Promise((r) => setTimeout(r, 400));

    const { mainQuali, mainRace } = await findMainQualifyingAndRace(
      m.meeting_key,
    );
    await new Promise((r) => setTimeout(r, 200));
    const { sprintQuali, sprintRace } = await findSprintSessions(m.meeting_key);

    const raceAt = mainRace?.date_start ?? m.date_start;
    const qualAt = mainQuali?.date_start ??
      new Date(new Date(raceAt).getTime() - 24 * 3600 * 1000).toISOString();

    const hasSprint = !!(sprintQuali && sprintRace);

    const { data: raceRow, error: rErr } = await c.from("races").upsert(
      {
        season_id: year,
        round: i + 1,
        name: m.meeting_name,
        circuit: m.location,
        qualifying_at: qualAt,
        race_at: raceAt,
        has_sprint: hasSprint,
        sprint_qualifying_at: sprintQuali?.date_start ?? null,
        sprint_race_at: sprintRace?.date_start ?? null,
      },
      { onConflict: "season_id,round" },
    ).select("id").single();
    if (rErr) throw rErr;
    if (raceRow?.id) {
      await syncRaceSessions(c, raceRow.id as string, m.meeting_key);
    }
    raceCount++;
    if (hasSprint) sprintCount++;
  }

  return {
    year,
    teams: teamRows.size,
    drivers: driverRows.length,
    races: raceCount,
    sprints: sprintCount,
  };
}

async function syncSeasonSessions(c: SupabaseClient, year: number) {
  const { data: races, error } = await c
    .from("races")
    .select("id, race_at")
    .eq("season_id", year)
    .order("round", { ascending: true });
  if (error) throw error;

  let synced = 0;
  const errors: unknown[] = [];
  for (const race of races ?? []) {
    try {
      const meeting = await findMeeting(year, new Date(race.race_at as string));
      if (!meeting) throw new Error("OpenF1 meeting not found");
      await syncRaceSessions(c, race.id as string, meeting.meeting_key);
      synced++;
      await new Promise((r) => setTimeout(r, 250));
    } catch (e) {
      errors.push({ race_id: race.id, error: String(e) });
    }
  }

  return { year, synced, errors };
}
