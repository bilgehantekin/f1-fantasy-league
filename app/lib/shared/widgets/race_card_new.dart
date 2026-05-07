import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/env.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../country_flags.dart';
import '../models.dart';
import 'live_pulse_dot.dart';

enum RaceCardKind { main, sprint }

typedef RaceCardEntry = ({Race race, RaceCardKind kind});

const previousRaceDelay = Duration(hours: 3);

bool countsAsPreviousRace(Race race, {DateTime? now}) {
  final t = now ?? DateTime.now();
  if (race.status == RaceStatus.cancelled) return true;
  return !race.raceAt.add(previousRaceDelay).isAfter(t);
}

List<Race> buildPreviousAndNextRaces(List<Race> races, {DateTime? now}) {
  if (races.isEmpty) return const [];
  final t = now ?? DateTime.now();
  final sorted = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
  Race? previous;
  Race? next;
  for (final race in sorted) {
    if (countsAsPreviousRace(race, now: t)) {
      previous = race;
    } else {
      next ??= race;
    }
  }
  final selected = <Race>[];
  if (previous != null) selected.add(previous);
  if (next != null && next.id != previous?.id) selected.add(next);
  return selected;
}

Future<RaceCardKind?> showRaceKindPicker(
  BuildContext context, {
  required Race race,
  required String title,
  bool mainSaved = false,
  bool sprintSaved = false,
}) {
  if (!race.hasSprint) {
    return Future.value(RaceCardKind.main);
  }

  return showModalBottomSheet<RaceCardKind>(
    context: context,
    backgroundColor: AppColors.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                race.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0x99FFFFFF),
                ),
              ),
              const SizedBox(height: 16),
              _RaceKindOption(
                label: AppLocalizations.of(context).sprintRace,
                subtitle: _eventSubtitle(
                  context,
                  race.sprintRaceAt,
                  effectiveRaceCardNavigationStatus((
                    race: race,
                    kind: RaceCardKind.sprint,
                  )),
                ),
                icon: Icons.bolt_outlined,
                saved: sprintSaved,
                onTap: () => Navigator.of(context).pop(RaceCardKind.sprint),
              ),
              const SizedBox(height: 10),
              _RaceKindOption(
                label: AppLocalizations.of(context).mainRace,
                subtitle: _eventSubtitle(
                  context,
                  race.raceAt,
                  effectiveRaceCardNavigationStatus((
                    race: race,
                    kind: RaceCardKind.main,
                  )),
                ),
                icon: Icons.flag_outlined,
                saved: mainSaved,
                onTap: () => Navigator.of(context).pop(RaceCardKind.main),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _eventSubtitle(BuildContext context, DateTime? at, RaceStatus status) {
  final l = AppLocalizations.of(context);
  final statusLabel = switch (status) {
    RaceStatus.upcoming => l.openForPredictions,
    RaceStatus.locked => l.locked,
    RaceStatus.live => l.live,
    RaceStatus.finished => l.finished,
    RaceStatus.cancelled => l.canceled,
  };
  if (at == null) return statusLabel;
  final date = DateFormat(
    'd MMM HH:mm',
    Intl.getCurrentLocale(),
  ).format(at.toLocal());
  return '$date · $statusLabel';
}

class _RaceKindOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool saved;
  final VoidCallback onTap;

  const _RaceKindOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A26),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF15151E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.f1Red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (saved) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xB3FFFFFF),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir Race listesini sprint kartlarını da üreterek positionlar.
///
/// `pinFeaturedRace = false` (ana ekran): tüm kartlar kronolojik (eski → yeni).
///
/// `pinFeaturedRace = true` (lig detayı): "featured race weekend" en üstte
/// kalır (sprint + ana yarış, sprint daima ana yarıştan önce). Featured =
/// ana yarış bitiminden 24 saat geçmemiş ilk yarış. Bu sayede:
///   - Yarış haftası boyunca (sprint bitse bile) iki kart da üstte kalır.
///   - Main race bitiminden 24 saat sonra featured otomatik olarak bir
///     sonraki yarışa kayar; eski yarış kronolojik positionsına düşer.
///   - Bu hafta yarış yoksa en yakın gelecek yarış featured olur.
List<RaceCardEntry> buildOrderedRaceCards(
  List<Race> races, {
  DateTime? now,
  bool pinFeaturedRace = false,
  Duration featuredCooldown = const Duration(hours: 24),
}) {
  final t = now ?? DateTime.now();
  final entries = <RaceCardEntry>[];
  for (final r in races) {
    if (r.hasSprint) entries.add((race: r, kind: RaceCardKind.sprint));
    entries.add((race: r, kind: RaceCardKind.main));
  }

  DateTime keyDate(RaceCardEntry e) => e.kind == RaceCardKind.sprint
      ? (e.race.sprintRaceAt ?? e.race.sprintQualifyingAt ?? e.race.raceAt)
      : e.race.raceAt;

  entries.sort((a, b) => keyDate(a).compareTo(keyDate(b)));

  if (!pinFeaturedRace) return entries;

  final sortedRaces = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
  Race? featured;
  for (final r in sortedRaces) {
    if (r.raceAt.add(featuredCooldown).isAfter(t)) {
      featured = r;
      break;
    }
  }
  if (featured == null) return entries;

  final featuredEntries = <RaceCardEntry>[];
  final rest = <RaceCardEntry>[];
  for (final e in entries) {
    if (e.race.id == featured.id) {
      featuredEntries.add(e);
    } else {
      rest.add(e);
    }
  }
  return [...featuredEntries, ...rest];
}

RaceStatus effectiveRaceCardStatus(RaceCardEntry entry, {DateTime? now}) {
  final t = now ?? DateTime.now();
  final rawStatus = entry.kind == RaceCardKind.sprint
      ? entry.race.sprintStatus
      : entry.race.status;
  if (rawStatus == RaceStatus.finished || rawStatus == RaceStatus.cancelled) {
    return rawStatus;
  }

  if (_isRaceEventActive(entry, t)) {
    return RaceStatus.live;
  }

  if (rawStatus == RaceStatus.locked) return RaceStatus.locked;

  final lockAt = entry.kind == RaceCardKind.sprint
      ? entry.race.effectiveSprintLockAt
      : entry.race.effectiveLockAt;
  if (lockAt == null) return RaceStatus.locked;
  return t.isAfter(lockAt) ? RaceStatus.locked : RaceStatus.upcoming;
}

RaceStatus effectiveRaceCardNavigationStatus(
  RaceCardEntry entry, {
  DateTime? now,
}) {
  final status = effectiveRaceCardStatus(entry, now: now);
  if (status == RaceStatus.finished || status == RaceStatus.cancelled) {
    return status;
  }
  return _debugStatusOverrideForEntry(entry) ?? status;
}

RaceStatus effectiveRaceCardDisplayStatus(
  RaceCardEntry entry, {
  DateTime? now,
}) {
  final ownStatus = effectiveRaceCardNavigationStatus(entry, now: now);
  if (ownStatus == RaceStatus.live) return RaceStatus.live;

  final t = now ?? DateTime.now();
  if (entry.kind == RaceCardKind.main && entry.race.hasSprint) {
    final sprintEntry = (race: entry.race, kind: RaceCardKind.sprint);
    if (effectiveRaceCardNavigationStatus(sprintEntry, now: t) ==
        RaceStatus.live) {
      return RaceStatus.live;
    }
  }

  return ownStatus;
}

RaceStatus? _debugStatusOverrideForEntry(RaceCardEntry entry) {
  if (!_debugAppliesToRace(entry.race) ||
      Env.raceCardDebugStatus.trim().isEmpty) {
    return null;
  }
  final normalizedStatus = Env.raceCardDebugStatus.trim().toLowerCase();
  final status = RaceStatus.values
      .where((s) => s.name == normalizedStatus)
      .firstOrNull;
  if (status == null) return null;

  if (status == RaceStatus.live) {
    final session = Env.raceCardDebugSession.trim().toUpperCase();
    if (session == 'SQ' || session == 'Q') return RaceStatus.locked;
    if (session == 'SR') {
      return entry.kind == RaceCardKind.sprint ? RaceStatus.live : null;
    }
    if (session == 'R') {
      return entry.kind == RaceCardKind.main ? RaceStatus.live : null;
    }
    if (session.isNotEmpty) return null;
  }

  return status;
}

bool _debugAppliesToRace(Race race) {
  if (Env.isProd || Env.raceCardDebugRace.trim().isEmpty) return false;
  return race.name.toLowerCase().contains(
    Env.raceCardDebugRace.trim().toLowerCase(),
  );
}

bool _isRaceEventActive(RaceCardEntry entry, DateTime now) {
  final startsAt = entry.kind == RaceCardKind.sprint
      ? entry.race.sprintRaceAt
      : entry.race.raceAt;
  if (startsAt == null || now.isBefore(startsAt)) return false;

  final sessionEndsAt = _matchingRaceSession(entry)?.endsAt;
  final fallbackDuration = entry.kind == RaceCardKind.sprint
      ? const Duration(hours: 2)
      : const Duration(hours: 4);
  final endsAt = sessionEndsAt ?? startsAt.add(fallbackDuration);
  return now.isBefore(endsAt);
}

RaceSession? _matchingRaceSession(RaceCardEntry entry) {
  final target = entry.kind == RaceCardKind.sprint
      ? entry.race.sprintRaceAt
      : entry.race.raceAt;
  if (target == null) return null;

  for (final session in entry.race.sessions) {
    if (session.startsAt.isAtSameMomentAs(target)) return session;
  }
  return null;
}

class RaceCardNew extends StatelessWidget {
  final Race race;
  final VoidCallback onTap;
  final RaceCardKind kind;
  final bool? predictionSaved;
  final int? savedPredictionCount;
  final int? totalPredictionCount;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool keepStartLightsVisible;

  /// Lig bağlamında mı gösteriliyor? Calendar (ana ekran) için false:
  /// biten yarışlarda kullanıcının skor/positionlamasını gizler, canlı yarışlarda
  /// ilerleme bilgisini göstermez.
  final bool showLeagueContext;

  const RaceCardNew({
    super.key,
    required this.race,
    required this.onTap,
    this.predictionSaved,
    this.savedPredictionCount,
    this.totalPredictionCount,
    this.actionLabel,
    this.actionIcon,
    this.keepStartLightsVisible = false,
    this.showLeagueContext = true,
    this.kind = RaceCardKind.main,
  });

  bool get _isSprint => kind == RaceCardKind.sprint;

  RaceStatus get _status => kind == RaceCardKind.main
      ? effectiveRaceCardDisplayStatus((race: race, kind: kind))
      : effectiveRaceCardNavigationStatus((race: race, kind: kind));

  DateTime? get _qualifyingAt =>
      _isSprint ? race.sprintQualifyingAt : race.qualifyingAt;

  DateTime? get _raceAt => _isSprint ? race.sprintRaceAt : race.raceAt;

  int get _predictionTotal => totalPredictionCount ?? (race.hasSprint ? 2 : 1);

  int get _predictionSavedCount {
    final explicit = savedPredictionCount;
    if (explicit != null) return explicit.clamp(0, _predictionTotal);
    return predictionSaved == true ? _predictionTotal : 0;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final status = _status;
    final l = AppLocalizations.of(context);

    final (
      bgColor,
      borderColor,
      accentColor,
      statusIcon,
      statusLabel,
    ) = switch (status) {
      RaceStatus.upcoming => (
        AppColors.surfaceLow,
        AppColors.lockGreen,
        AppColors.lockGreen,
        Icons.flag_outlined,
        l.openForPicks,
      ),
      RaceStatus.locked => (
        AppColors.surfaceLow,
        AppColors.lockOrange,
        AppColors.lockOrange,
        Icons.lock_outline,
        l.locked.toUpperCase(),
      ),
      RaceStatus.live => (
        AppColors.surfaceLow,
        AppColors.liveRed,
        AppColors.liveRed,
        Icons.circle,
        l.liveUpper,
      ),
      RaceStatus.finished => (
        AppColors.surface,
        AppColors.finished,
        AppColors.finished,
        Icons.check_circle_outline,
        l.finished.toUpperCase(),
      ),
      RaceStatus.cancelled => (
        AppColors.surface,
        AppColors.finished,
        AppColors.finished,
        Icons.block,
        l.canceled.toUpperCase(),
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                Row(
                  children: [
                    if (status == RaceStatus.live)
                      const LivePulseDot(size: 14)
                    else
                      Icon(statusIcon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: tt.labelSmall?.copyWith(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showLeagueContext) ...[
                      const Spacer(),
                      _PredictionBadge(
                        saved: _predictionSavedCount,
                        total: _predictionTotal,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Race info
                Row(
                  children: [
                    Text(
                      'R${race.round}',
                      style: tt.titleMedium?.copyWith(
                        color: AppColors.f1Red,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      flagFor(race.name),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isSprint ? '${race.name} · Sprint' : race.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  race.circuit,
                  style: tt.bodyMedium?.copyWith(
                    color: const Color(0x99FFFFFF), // white/60
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _StartLightsPanel(
                  sessions: _buildStartLightSessions(DateTime.now()),
                ),
                const SizedBox(height: 12),

                // Status-specific content
                if (status == RaceStatus.upcoming ||
                    status == RaceStatus.locked)
                  _buildUpcomingContent(context)
                else ...[
                  if (status == RaceStatus.live) _buildLiveContent(context),
                  if (status == RaceStatus.finished && showLeagueContext)
                    _buildFinishedContent(context),
                  _buildScheduleRow(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_StartLightSession> _buildStartLightSessions(DateTime now) {
    final pinnedLightState = _pinnedLightState(now);

    if (race.sessions.isNotEmpty) {
      final completedOverride = pinnedLightState ?? _completedLightState(now);
      if (completedOverride != null) {
        return race.sessions
            .take(5)
            .map(
              (session) => _StartLightSession(
                label: session.shortLabel,
                state: completedOverride,
              ),
            )
            .toList();
      }

      final isRaceWeek =
          now.isAfter(
            race.sessions.first.startsAt.subtract(const Duration(days: 1)),
          ) &&
          now.isBefore(
            (race.sessions.last.endsAt ?? race.sessions.last.startsAt).add(
              const Duration(hours: 4),
            ),
          );
      final forceInactive = !isRaceWeek || _status == RaceStatus.cancelled;
      final sessions = race.sessions
          .take(5)
          .map(
            (session) => _StartLightSession(
              label: session.shortLabel,
              state: _lightStateFor(
                session.startsAt,
                now,
                forceInactive: forceInactive,
                endsAt: session.endsAt,
              ),
            ),
          )
          .toList();
      return _applyDebugSessionOverride(sessions);
    }

    final qAt = _qualifyingAt;
    final rAt = _raceAt;
    final useSprintWeekendLayout = race.hasSprint;
    final completedOverride = pinnedLightState ?? _completedLightState(now);
    final firstKnownSession = useSprintWeekendLayout
        ? (race.sprintQualifyingAt ?? race.sprintRaceAt ?? qAt ?? rAt)
        : (qAt ?? rAt);
    final isRaceWeek =
        firstKnownSession != null &&
        now.isAfter(firstKnownSession.subtract(const Duration(days: 3))) &&
        rAt != null &&
        now.isBefore(rAt.add(const Duration(hours: 4)));
    final forceInactive =
        !keepStartLightsVisible &&
        (!isRaceWeek || _status == RaceStatus.cancelled);

    if (useSprintWeekendLayout) {
      final sqAt = race.sprintQualifyingAt ?? qAt;
      final srAt = race.sprintRaceAt;
      final p1At = sqAt?.subtract(const Duration(hours: 4));
      return _applyDebugSessionOverride([
        _StartLightSession(
          label: 'P1',
          state:
              completedOverride ??
              _lightStateFor(p1At, now, forceInactive: forceInactive),
        ),
        _StartLightSession(
          label: 'SQ',
          state:
              completedOverride ??
              _lightStateFor(sqAt, now, forceInactive: forceInactive),
        ),
        _StartLightSession(
          label: 'SR',
          state:
              completedOverride ??
              _lightStateFor(srAt, now, forceInactive: forceInactive),
        ),
        _StartLightSession(
          label: 'Q',
          state:
              completedOverride ??
              _lightStateFor(qAt, now, forceInactive: forceInactive),
        ),
        _StartLightSession(
          label: 'R',
          state:
              completedOverride ??
              _lightStateFor(rAt, now, forceInactive: forceInactive),
        ),
      ]);
    }

    final p1At = qAt?.subtract(const Duration(days: 2));
    final p2At = qAt?.subtract(const Duration(days: 1));
    final p3At = qAt?.subtract(const Duration(hours: 4));
    return _applyDebugSessionOverride([
      _StartLightSession(
        label: 'P1',
        state:
            completedOverride ??
            _lightStateFor(p1At, now, forceInactive: forceInactive),
      ),
      _StartLightSession(
        label: 'P2',
        state:
            completedOverride ??
            _lightStateFor(p2At, now, forceInactive: forceInactive),
      ),
      _StartLightSession(
        label: 'P3',
        state:
            completedOverride ??
            _lightStateFor(p3At, now, forceInactive: forceInactive),
      ),
      _StartLightSession(
        label: 'Q',
        state:
            completedOverride ??
            _lightStateFor(qAt, now, forceInactive: forceInactive),
      ),
      _StartLightSession(
        label: 'R',
        state:
            completedOverride ??
            _lightStateFor(rAt, now, forceInactive: forceInactive),
      ),
    ]);
  }

  _StartLightState? _completedLightState(DateTime now) {
    if (_status != RaceStatus.finished) return null;
    final finishedAt = _raceAt;
    if (finishedAt == null) return _StartLightState.finished;
    return now.isBefore(finishedAt.add(const Duration(days: 1)))
        ? _StartLightState.finished
        : _StartLightState.inactive;
  }

  _StartLightState? _pinnedLightState(DateTime now) {
    if (!keepStartLightsVisible) return null;
    final startsAt = _raceAt;
    if (_status == RaceStatus.finished ||
        _status == RaceStatus.cancelled ||
        (startsAt != null && !startsAt.isAfter(now))) {
      return _StartLightState.finished;
    }
    return _StartLightState.upcoming;
  }

  List<_StartLightSession> _applyDebugSessionOverride(
    List<_StartLightSession> sessions,
  ) {
    final target = Env.raceCardDebugSession.trim().toUpperCase();
    if (!_debugAppliesToRace(race) || target.isEmpty) return sessions;
    final targetIndex = sessions.indexWhere(
      (session) => session.label.toUpperCase() == target,
    );
    if (targetIndex == -1) return sessions;

    return [
      for (var i = 0; i < sessions.length; i++)
        _StartLightSession(
          label: sessions[i].label,
          state: i < targetIndex
              ? _StartLightState.finished
              : i == targetIndex
              ? _StartLightState.live
              : _StartLightState.upcoming,
        ),
    ];
  }

  _StartLightState _lightStateFor(
    DateTime? startsAt,
    DateTime now, {
    required bool forceInactive,
    DateTime? endsAt,
  }) {
    if (forceInactive || startsAt == null) return _StartLightState.inactive;
    final effectiveEndsAt = endsAt ?? startsAt.add(const Duration(hours: 2));
    if (now.isBefore(startsAt)) return _StartLightState.upcoming;
    if (now.isBefore(effectiveEndsAt)) return _StartLightState.live;
    return _StartLightState.finished;
  }

  Widget _buildUpcomingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleRow(context),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          _CardAction(label: actionLabel!, icon: actionIcon),
        ],
      ],
    );
  }

  Widget _buildScheduleRow(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final qAt = _qualifyingAt;
    final rAt = _raceAt;
    if (qAt == null || rAt == null) {
      return const SizedBox.shrink();
    }
    final qDate = DateFormat(
      'd MMM',
      Intl.getCurrentLocale(),
    ).format(qAt.toLocal());
    final qTime = DateFormat(
      'HH:mm',
      Intl.getCurrentLocale(),
    ).format(qAt.toLocal());
    final rDate = DateFormat(
      'd MMM',
      Intl.getCurrentLocale(),
    ).format(rAt.toLocal());
    final rTime = DateFormat(
      'HH:mm',
      Intl.getCurrentLocale(),
    ).format(rAt.toLocal());

    return Container(
      padding: const EdgeInsets.only(top: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F1F2E), width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'Qualifying: ',
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          Text(
            '$qDate $qTime',
            style: tt.bodySmall?.copyWith(
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Race: ',
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          Text(
            '$rDate $rTime',
            style: tt.bodySmall?.copyWith(
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveContent(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (!Env.enableDemoContent) {
      return Text(
        _isSprint ? 'Sprint live - open' : 'Open live screen',
        style: tt.bodyMedium?.copyWith(
          color: const Color(0x99FFFFFF),
          fontSize: 14,
        ),
      );
    }

    const currentLap = 43;
    const totalLaps = 50;
    const progress = 86.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TUR $currentLap/$totalLaps',
              style: tt.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${progress.toInt()}%',
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: const Color(0xFF15151E),
              valueColor: const AlwaysStoppedAnimation(AppColors.liveRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedContent(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (!Env.enableDemoContent) {
      return Text(
        AppLocalizations.of(context).viewWeeklySummary,
        style: tt.bodyMedium?.copyWith(
          color: const Color(0x99FFFFFF),
          fontSize: 14,
        ),
      );
    }

    const userScore = 47;
    const userPosition = 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).yourScore,
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$userScore',
                  style: tt.displayMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'PTS',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0x80FFFFFF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your rank',
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (userPosition == 1)
                  const Text('🥇', style: TextStyle(fontSize: 28)),
                if (userPosition == 2)
                  const Text('🥈', style: TextStyle(fontSize: 28)),
                if (userPosition == 3)
                  const Text('🥉', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  '#$userPosition',
                  style: tt.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

enum _StartLightState { inactive, upcoming, live, finished }

class _StartLightSession {
  final String label;
  final _StartLightState state;

  const _StartLightSession({required this.label, required this.state});
}

class _StartLightsPanel extends StatelessWidget {
  final List<_StartLightSession> sessions;

  const _StartLightsPanel({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08080F), Color(0xFF050509)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, -2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            Expanded(child: _StartLightColumn(session: sessions[i])),
            if (i != sessions.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _StartLightColumn extends StatefulWidget {
  final _StartLightSession session;

  const _StartLightColumn({required this.session});

  @override
  State<_StartLightColumn> createState() => _StartLightColumnState();
}

class _StartLightColumnState extends State<_StartLightColumn> {
  final _tooltipKey = GlobalKey<TooltipState>();
  static const _liveLightColor = Color(0xFFFFD43B);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final active = session.state == _StartLightState.live;
    final labelColor = switch (session.state) {
      _StartLightState.live => _liveLightColor,
      _StartLightState.finished => Colors.white.withValues(alpha: 0.32),
      _StartLightState.upcoming => Colors.white.withValues(alpha: 0.55),
      _StartLightState.inactive => Colors.white.withValues(alpha: 0.18),
    };

    return Tooltip(
      key: _tooltipKey,
      message: '${session.label}: ${_startLightDescription(session.label)}',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StartLightBulb(state: session.state),
            const SizedBox(height: 6),
            Text(
              session.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: labelColor,
              ),
            ),
            if (active) const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}

String _startLightDescription(String label) {
  return switch (label.trim().toUpperCase()) {
    'P1' || 'FP1' || 'ANT1' => 'Practice 1',
    'P2' || 'FP2' || 'ANT2' => 'Practice 2',
    'P3' || 'FP3' || 'ANT3' => 'Practice 3',
    'SQ' || 'SS' => 'Sprint Qualifying',
    'SR' || 'S' => 'Sprint Race',
    'Q' => 'Qualifying',
    'R' => 'Race',
    _ => label,
  };
}

class _StartLightBulb extends StatelessWidget {
  final _StartLightState state;

  const _StartLightBulb({required this.state});

  static const _liveLightColor = Color(0xFFFFD43B);

  @override
  Widget build(BuildContext context) {
    final (lit, color, glow) = switch (state) {
      _StartLightState.finished => (
        true,
        const Color(0xFFFF1010),
        const Color(0xFFFF3030),
      ),
      _StartLightState.live => (true, _liveLightColor, const Color(0xFFFFE066)),
      _StartLightState.upcoming => (
        true,
        AppColors.lockGreen,
        const Color(0xFF3FE890),
      ),
      _StartLightState.inactive => (
        false,
        const Color(0xFF14141C),
        Colors.transparent,
      ),
    };

    final bulb = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.85,
          colors: lit
              ? [_lighten(color), color, _darken(color)]
              : const [Color(0xFF2A2A36), Color(0xFF14141C), Color(0xFF08080C)],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: 0.54),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(color: glow.withValues(alpha: 0.8), blurRadius: 5),
                const BoxShadow(
                  color: Color(0x80000000),
                  offset: Offset(0, -1),
                  blurRadius: 2,
                  spreadRadius: -1,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: lit
          ? Align(
              alignment: const Alignment(-0.38, -0.52),
              child: Container(
                width: 7,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            )
          : null,
    );

    if (state != _StartLightState.live) return bulb;

    return _PulsingStartLight(child: bulb);
  }

  Color _lighten(Color color) {
    return Color.fromARGB(
      255,
      (color.r * 255 + (255 - color.r * 255) * 0.4).round(),
      (color.g * 255 + (255 - color.g * 255) * 0.4).round(),
      (color.b * 255 + (255 - color.b * 255) * 0.4).round(),
    );
  }

  Color _darken(Color color) {
    return Color.fromARGB(
      255,
      (color.r * 255 * 0.55).round(),
      (color.g * 255 * 0.55).round(),
      (color.b * 255 * 0.55).round(),
    );
  }
}

class _PulsingStartLight extends StatefulWidget {
  final Widget child;

  const _PulsingStartLight({required this.child});

  @override
  State<_PulsingStartLight> createState() => _PulsingStartLightState();
}

class _PulsingStartLightState extends State<_PulsingStartLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _CardAction({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.f1Red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.edit_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionBadge extends StatelessWidget {
  final int saved;
  final int total;

  const _PredictionBadge({required this.saved, required this.total});

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xB3FFFFFF);
    const textColor = Color(0xCCFFFFFF);
    final suffix = '$saved/$total';
    final hasPrediction = saved > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasPrediction
              ? Icons.check_circle_outline
              : Icons.radio_button_unchecked,
          size: 15,
          color: iconColor,
        ),
        const SizedBox(width: 6),
        Text(
          hasPrediction ? 'Prediction made $suffix' : 'No prediction',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
