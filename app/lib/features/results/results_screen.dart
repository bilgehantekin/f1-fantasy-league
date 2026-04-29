import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/podium_display.dart';
import '../prediction/prediction_controller.dart';

final raceResultProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, raceId) async {
  final rows = await supabase
      .from('race_results')
      .select()
      .eq('race_id', raceId)
      .limit(1);
  return rows.isEmpty ? null : rows.first;
});

class ResultsScreen extends ConsumerWidget {
  final String raceId;
  const ResultsScreen({super.key, required this.raceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(predictionProvider(raceId));
    final resultAsync = ref.watch(raceResultProvider(raceId));

    return Scaffold(
      appBar: AppBar(title: const Text('YARIŞ SONUCU')),
      body: raceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (race) => driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (drivers) {
            Driver? byId(String? id) {
              if (id == null) return null;
              for (final d in drivers) {
                if (d.id == id) return d;
              }
              return null;
            }

            final result = resultAsync.asData?.value;
            final prediction = predictionAsync.asData?.value;

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                _RaceHero(race: race),
                const SizedBox(height: 16),
                if (result != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text('PODIUM',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PodiumDisplay(
                      p1: byId(result['p1'] as String?),
                      p2: byId(result['p2'] as String?),
                      p3: byId(result['p3'] as String?),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const _NoResultYet(),
                if (prediction != null)
                  _ScoreCard(
                    prediction: prediction,
                    drivers: drivers,
                    result: result,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Bu yarış için tahmin yapmamışsın.',
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            );
          },
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

class _NoResultYet extends StatelessWidget {
  const _NoResultYet();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.hourglass_top, size: 32, color: Colors.white54),
                SizedBox(height: 8),
                Text('Resmi sonuç henüz gelmedi',
                    textAlign: TextAlign.center),
                SizedBox(height: 4),
                Text('Yarış bitince OpenF1\'den otomatik çekilecek.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

class _ScoreCard extends StatelessWidget {
  final Prediction prediction;
  final List<Driver> drivers;
  final Map<String, dynamic>? result;
  const _ScoreCard({
    required this.prediction,
    required this.drivers,
    required this.result,
  });

  Driver? _byId(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    String code(String? id) => _byId(id)?.code ?? '—';
    bool? eq(String? a, String? b) => result == null
        ? null
        : (a != null && b != null && a == b);

    final r = result;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prediction.score != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.f1Red,
                    AppColors.f1Red.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text('TOPLAM PUAN',
                      style: tt.labelSmall?.copyWith(letterSpacing: 2)),
                  Text('${prediction.score}',
                      style: tt.displayLarge?.copyWith(fontSize: 64)),
                ],
              ),
            ),
          Text('TAHMİNİN', style: tt.labelLarge),
          const SizedBox(height: 8),
          PointsBreakdownTile(
            label: 'KAZANAN',
            value:
                '${code(prediction.winnerDriverId)} → ${code(r?['p1'] as String?)}',
            correct: eq(prediction.winnerDriverId, r?['p1'] as String?),
          ),
          PointsBreakdownTile(
            label: 'PODIUM',
            value:
                '1.${code(prediction.p1Id)} • 2.${code(prediction.p2Id)} • 3.${code(prediction.p3Id)}',
            correct: r == null
                ? null
                : (prediction.p1Id == r['p1'] &&
                    prediction.p2Id == r['p2'] &&
                    prediction.p3Id == r['p3']),
          ),
          PointsBreakdownTile(
            label: 'POLE',
            value:
                '${code(prediction.poleDriverId)} → ${code(r?['pole'] as String?)}',
            correct: eq(prediction.poleDriverId, r?['pole'] as String?),
          ),
          PointsBreakdownTile(
            label: 'EN HIZLI TUR',
            value:
                '${code(prediction.fastestLapDriverId)} → ${code(r?['fastest_lap'] as String?)}',
            correct:
                eq(prediction.fastestLapDriverId, r?['fastest_lap'] as String?),
          ),
          PointsBreakdownTile(
            label: 'DNF',
            value: r == null
                ? '${prediction.dnfCount ?? "—"}'
                : '${prediction.dnfCount ?? "—"} → ${r['dnf_count']}',
            correct: r == null
                ? null
                : prediction.dnfCount == r['dnf_count'],
          ),
          PointsBreakdownTile(
            label: 'JOKER',
            value: r == null
                ? (prediction.jokerOption ?? '—')
                : '${prediction.jokerOption ?? "—"} → ${r['joker_correct'] ?? "—"}',
            correct: r == null
                ? null
                : (prediction.jokerOption != null &&
                    prediction.jokerOption == r['joker_correct']),
          ),
        ],
      ),
    );
  }
}
