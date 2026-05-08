import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/error_messages.dart';
import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/live_pulse_dot.dart';
import '../prediction/prediction_controller.dart';
import '../prediction/prediction_screen.dart';
import 'live_controller.dart';

class LiveRaceScreen extends ConsumerWidget {
  final String raceId;
  final String? leagueId;
  final bool sprintMode;
  const LiveRaceScreen({
    super.key,
    required this.raceId,
    this.leagueId,
    this.sprintMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionKey = PredictionKey(raceId: raceId, leagueId: leagueId);
    final predictionAsync = ref.watch(predictionProvider(predictionKey));
    final sprintPredictionAsync = ref.watch(
      sprintPredictionProvider(predictionKey),
    );
    final positionsAsync = ref.watch(livePositionsProvider(raceId));
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          tooltip: l.back,
          onPressed: () => safeBack(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LivePulseDot(size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                raceAsync.maybeWhen(
                  data: (r) => '${l.liveUpper} · ${r.name.toUpperCase()}',
                  orElse: () => l.liveUpper,
                ),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: raceAsync.when(
        loading: () => AppLoadingState(label: l.liveScreenLoading),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(raceProvider(raceId)),
        ),
        data: (race) => driversAsync.when(
          loading: () => AppLoadingState(label: l.driversLoading),
          error: (e, _) => AppErrorState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(driversProvider),
          ),
          data: (drivers) => positionsAsync.when(
            loading: () => AppLoadingState(label: l.liveDataLoading),
            error: (e, _) => AppErrorState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(livePositionsProvider(raceId)),
            ),
            data: (positions) {
              final mainPrediction = predictionAsync.asData?.value;
              final sprintPrediction = sprintPredictionAsync.asData?.value;
              final showPredictionSections = leagueId != null;
              final useSprintPrediction = sprintMode && race.hasSprint;
              final predictionSections = useSprintPrediction
                  ? buildReadOnlySprintPredictionSections(
                      context: context,
                      prediction:
                          sprintPrediction ?? SprintPrediction(raceId: raceId),
                      drivers: drivers,
                    )
                  : buildReadOnlyMainPredictionSections(
                      context: context,
                      prediction: mainPrediction ?? Prediction(raceId: raceId),
                      drivers: drivers,
                      race: race,
                      joker: ref.watch(jokerProvider(raceId)).asData?.value,
                    );
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _LiveHeader(race: race),
                  const SizedBox(height: 24),
                  _SectionTitle(label: l.liveOrder),
                  if (positions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          l.noLiveDataYet,
                          style: const TextStyle(color: Color(0x99FFFFFF)),
                        ),
                      ),
                    )
                  else
                    _TopPositions(positions: positions, drivers: drivers),
                  const SizedBox(height: 24),
                  if (Env.enableDemoContent) ...[
                    _SectionTitle(label: l.fastestLap),
                    const _FastestLap(),
                    const SizedBox(height: 24),
                  ],
                  if (showPredictionSections) ...[
                    _SectionTitle(label: l.yourPrediction),
                    const SizedBox(height: 12),
                    ...predictionSections,
                    const SizedBox(height: 24),
                  ],
                  if (Env.enableDemoContent) ...[
                    _SectionTitle(label: l.recentEvents),
                    const _LatestEvents(),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  final Race race;
  const _LiveHeader({required this.race});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!Env.enableDemoContent) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A26),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xFFFF2D55), width: 4),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).liveTimingWaiting,
          style: const TextStyle(color: Color(0xB3FFFFFF)),
        ),
      );
    }

    const currentLap = 67;
    const totalLaps = 78;
    const progress = 85.9;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF2D55), width: 4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${l.lapShort} $currentLap',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    ' / $totalLaps',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1:42:33',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xFF15151E),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF2D55)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE10600),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPositions extends StatelessWidget {
  final List<LivePosition> positions;
  final List<Driver> drivers;

  const _TopPositions({required this.positions, required this.drivers});

  Driver? _byId(String id) {
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...positions]
      ..sort((a, b) {
        if (a.position == null && b.position == null) return 0;
        if (a.position == null) return 1;
        if (b.position == null) return -1;
        return a.position!.compareTo(b.position!);
      });

    final top8 = sorted.take(8).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < top8.length; i++)
            () {
              final p = top8[i];
              final d = _byId(p.driverId);
              if (d == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: i < top8.length - 1
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFF15151E),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        'P${p.position ?? '-'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            (d.teamColor ?? '#6E6E80').replaceAll('#', '0xFF'),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                d.code,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' · ${d.fullName.split(' ').last}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${(p.position ?? 0) * 0.5}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }(),
        ],
      ),
    );
  }
}

class _FastestLap extends StatelessWidget {
  const _FastestLap();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOR · Norris',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '1:12.345 · ${l.lapShort} 45',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestEvents extends StatelessWidget {
  const _LatestEvents();

  static const _events = <_EventItem>[
    _EventItem(
      lap: 67,
      code: 'PER',
      type: _EventType.dnfCrash,
      teamColor: 0xFF3671C6,
    ),
    _EventItem(
      lap: 65,
      code: 'NOR',
      type: _EventType.fastestLap,
      teamColor: 0xFFFF8000,
    ),
    _EventItem(
      lap: 58,
      code: 'HAM',
      type: _EventType.pitStop,
      teamColor: 0xFF27F4D2,
    ),
    _EventItem(
      lap: 52,
      code: 'SAI',
      type: _EventType.pitStop,
      teamColor: 0xFFE8002D,
    ),
  ];

  String _eventText(BuildContext context, _EventType type) {
    final l = AppLocalizations.of(context);
    switch (type) {
      case _EventType.dnfCrash:
        return l.eventDnfCrash;
      case _EventType.fastestLap:
        return l.eventFastestLap;
      case _EventType.pitStop:
        return l.eventPitStop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _events.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i < _events.length - 1
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFF15151E), width: 1),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${l.lapShort} ${_events[i].lap}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0x66FFFFFF),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(_events[i].teamColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _events[i].code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${_eventText(context, _events[i].type)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventItem {
  final int lap;
  final String code;
  final _EventType type;
  final int teamColor;
  const _EventItem({
    required this.lap,
    required this.code,
    required this.type,
    required this.teamColor,
  });
}

enum _EventType { dnfCrash, fastestLap, pitStop }
