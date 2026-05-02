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
  const dnfCount = countDnfResults(raceResults);

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

  // Sprint sonuçları
  if (sprintPayload) {
    const { error: spErr } = await c.from("sprint_results").upsert(
      sprintPayload,
    );
    if (spErr) throw spErr;
  }
  if (hasSprint) {
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
    sprint_ingested: !!sprintPayload,
    sprint_classification_rows: sprintClassification.length,
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
  return results.filter((r) => r.dnf || r.dns || r.dsq).length;
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

    const { error: rErr } = await c.from("races").upsert(
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
    );
    if (rErr) throw rErr;
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
