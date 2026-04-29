import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/driver_chip.dart';
import '../prediction/prediction_controller.dart';
import 'live_controller.dart';

class LiveRaceScreen extends ConsumerWidget {
  final String raceId;
  const LiveRaceScreen({super.key, required this.raceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(predictionProvider(raceId));
    final positionsAsync = ref.watch(livePositionsProvider(raceId));
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.liveRed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('CANLI', style: tt.titleLarge),
          ],
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
                  _RaceHero(race: race),
                  if (comparisons.any((c) => c.predicted != null))
                    _ComparisonPanel(comparisons: comparisons),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                            width: 4, height: 18, color: AppColors.f1Red),
                        const SizedBox(width: 8),
                        Text('CANLI SIRALAMA', style: tt.labelLarge),
                      ],
                    ),
                  ),
                  if (positions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.signal_wifi_off,
                                  color: Colors.white60),
                              const SizedBox(height: 8),
                              Text('Henüz canlı veri yok',
                                  style: tt.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                  'Yarış başlayınca pozisyonlar burada akmaya başlar.',
                                  textAlign: TextAlign.center,
                                  style: tt.bodySmall
                                      ?.copyWith(color: Colors.white60)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _LiveLeaderboard(
                      positions: positions,
                      drivers: drivers,
                      prediction: prediction,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RaceHero extends StatelessWidget {
  final Race race;
  const _RaceHero({required this.race});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A26), Color(0xFF0B0B12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('R${race.round}',
                  style: tt.labelLarge?.copyWith(color: AppColors.f1Red)),
              const SizedBox(width: 8),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(race.name, style: tt.displayMedium?.copyWith(fontSize: 26)),
          Text(race.circuit,
              style: tt.bodySmall?.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  final List<LiveComparison> comparisons;
  const _ComparisonPanel({required this.comparisons});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, color: AppColors.f1Red),
              const SizedBox(width: 8),
              Text('TAHMİNİN VS GERÇEK', style: tt.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in comparisons)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    width: 3,
                    color: c.matches == null
                        ? Colors.white24
                        : (c.matches! ? AppColors.lockGreen : AppColors.liveRed),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(c.label,
                        style: tt.labelSmall
                            ?.copyWith(color: Colors.white60, fontSize: 10)),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        if (c.predicted != null)
                          Expanded(
                            child: DriverChip(driver: c.predicted!, dense: true),
                          )
                        else
                          const Expanded(
                              child: Text('—',
                                  style: TextStyle(color: Colors.white38))),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            size: 14, color: Colors.white38),
                        const SizedBox(width: 8),
                        if (c.actual != null)
                          Expanded(
                            child: DriverChip(driver: c.actual!, dense: true),
                          )
                        else
                          const Expanded(
                              child: Text('—',
                                  style: TextStyle(color: Colors.white38))),
                      ],
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

class _LiveLeaderboard extends StatelessWidget {
  final List<LivePosition> positions;
  final List<Driver> drivers;
  final Prediction? prediction;
  const _LiveLeaderboard({
    required this.positions,
    required this.drivers,
    required this.prediction,
  });

  Driver? _byId(String id) {
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  bool _isPredicted(String driverId) {
    if (prediction == null) return false;
    return prediction!.winnerDriverId == driverId ||
        prediction!.p1Id == driverId ||
        prediction!.p2Id == driverId ||
        prediction!.p3Id == driverId ||
        prediction!.poleDriverId == driverId ||
        prediction!.fastestLapDriverId == driverId;
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
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          for (final p in sorted)
            () {
              final d = _byId(p.driverId);
              if (d == null) return const SizedBox.shrink();
              final inPodium = p.position != null && p.position! <= 3;
              final picked = _isPredicted(p.driverId);
              final medalColor = switch (p.position) {
                1 => const Color(0xFFFFD700),
                2 => const Color(0xFFC0C0C0),
                3 => const Color(0xFFCD7F32),
                _ => null,
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                  border: picked
                      ? Border.all(
                          color: AppColors.f1Red.withValues(alpha: 0.6),
                          width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        p.position == null ? '—' : '${p.position}',
                        style: tt.headlineMedium?.copyWith(
                          color: medalColor ??
                              (p.status == 'retired'
                                  ? Colors.white24
                                  : Colors.white),
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: DriverChip(driver: d, dense: true)),
                    if (p.status == 'retired')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('DNF',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.liveRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    if (picked && !inPodium)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.bookmark,
                            size: 14, color: AppColors.f1Red),
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
