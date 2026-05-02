import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets/live_pulse_dot.dart';
import '../prediction/prediction_controller.dart';
import 'live_controller.dart';

class LiveRaceScreen extends ConsumerWidget {
  final String raceId;
  const LiveRaceScreen({super.key, required this.raceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(
      predictionProvider(PredictionKey(raceId: raceId)),
    );
    final positionsAsync = ref.watch(livePositionsProvider(raceId));

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LivePulseDot(size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                raceAsync.maybeWhen(
                  data: (r) => 'LIVE · ${r.name.toUpperCase()}',
                  orElse: () => 'LIVE',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (race) => driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (drivers) => positionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (positions) {
              final prediction = predictionAsync.asData?.value;
              final comparisons = buildComparisons(
                prediction: prediction,
                positions: positions,
                drivers: drivers,
              );
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _LiveHeader(race: race),
                  const SizedBox(height: 24),
                  _SectionTitle(label: 'ÖN SIRALAMA'),
                  if (positions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Henüz canlı veri yok',
                          style: TextStyle(color: Color(0x99FFFFFF)),
                        ),
                      ),
                    )
                  else
                    _TopPositions(positions: positions, drivers: drivers),
                  const SizedBox(height: 24),
                  if (Env.enableDemoContent) ...[
                    _SectionTitle(label: 'EN HIZLI TUR'),
                    const _FastestLap(),
                    const SizedBox(height: 24),
                  ],
                  _SectionTitle(label: 'SENİN TAHMİNİN'),
                  comparisons.any((c) => c.predicted != null)
                      ? _PredictionComparison(comparisons: comparisons)
                      : Env.enableDemoContent
                      ? const _PredictionComparisonMock()
                      : const _NoPredictionLiveCard(),
                  const SizedBox(height: 24),
                  if (Env.enableDemoContent) ...[
                    _SectionTitle(label: 'SON OLAYLAR'),
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
        child: const Text(
          'Canlı zamanlama bilgisi yarış veri akışı gelince güncellenecek.',
          style: TextStyle(color: Color(0xB3FFFFFF)),
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
                  const Text(
                    'TUR $currentLap',
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

class _PredictionComparison extends StatelessWidget {
  final List<LiveComparison> comparisons;
  const _PredictionComparison({required this.comparisons});

  @override
  Widget build(BuildContext context) {
    final relevantComparisons = comparisons
        .where((c) => c.predicted != null)
        .toList();

    if (relevantComparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < relevantComparisons.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < relevantComparisons.length - 1 ? 8 : 0,
              ),
              child: _ComparisonRow(comparison: relevantComparisons[i]),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(color: Color(0xFF15151E), height: 1),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tahmini Skor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                '28-48 PTS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FastestLap extends StatelessWidget {
  const _FastestLap();

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOR · Norris',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  '1:12.345 · TUR 45',
                  style: TextStyle(
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
      text: 'DNF (Crash)',
      teamColor: 0xFF3671C6,
    ),
    _EventItem(
      lap: 65,
      code: 'NOR',
      text: 'En Hızlı Tur',
      teamColor: 0xFFFF8000,
    ),
    _EventItem(lap: 58, code: 'HAM', text: 'Pit Stop', teamColor: 0xFF27F4D2),
    _EventItem(lap: 52, code: 'SAI', text: 'Pit Stop', teamColor: 0xFFE8002D),
  ];

  @override
  Widget build(BuildContext context) {
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
                      'TUR ${_events[i].lap}',
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
                    '· ${_events[i].text}',
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
  final String text;
  final int teamColor;
  const _EventItem({
    required this.lap,
    required this.code,
    required this.text,
    required this.teamColor,
  });
}

enum _MockStatus { correct, wrong, partial, pending }

class _PredictionComparisonMock extends StatelessWidget {
  const _PredictionComparisonMock();

  @override
  Widget build(BuildContext context) {
    const rows = <(String, String, _MockStatus)>[
      ('Kazanan', 'VER', _MockStatus.correct),
      ('Podyum', 'VER LEC SAI', _MockStatus.partial),
      ('Pole', 'LEC', _MockStatus.correct),
      ('En Hızlı Tur', 'NOR', _MockStatus.correct),
      ('DNF', '3 (şimdi: 1)', _MockStatus.pending),
      ('Joker', 'Red Bull', _MockStatus.pending),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 8 : 0),
              child: _MockRow(
                label: rows[i].$1,
                value: rows[i].$2,
                status: rows[i].$3,
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(color: Color(0xFF15151E), height: 1),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tahmini Skor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                '28-48 PUAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPredictionLiveCard extends StatelessWidget {
  const _NoPredictionLiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Bu yarış için kayıtlı tahmin bulunamadı.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0x99FFFFFF)),
      ),
    );
  }
}

class _MockRow extends StatelessWidget {
  final String label;
  final String value;
  final _MockStatus status;
  const _MockRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      _MockStatus.correct => ('✓', const Color(0xFF00D26A)),
      _MockStatus.wrong => ('✗', const Color(0xFFFF2D55)),
      _MockStatus.partial => ('~', const Color(0xFFFF9F1C)),
      _MockStatus.pending => ('~', const Color(0x66FFFFFF)),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0x99FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              icon,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final LiveComparison comparison;
  const _ComparisonRow({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final statusIcon = comparison.matches == null
        ? '~'
        : comparison.matches!
        ? '✓'
        : '✗';

    final statusColor = comparison.matches == null
        ? const Color(0x66FFFFFF) // white/40
        : comparison.matches!
        ? const Color(0xFF00D26A)
        : const Color(0xFFFF2D55);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${comparison.label}:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        Row(
          children: [
            Text(
              comparison.predicted?.code ?? '—',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              statusIcon,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
