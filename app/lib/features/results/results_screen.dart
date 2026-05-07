import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error_messages.dart';
import '../../core/navigation.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../prediction/prediction_controller.dart';

final raceResultProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, raceId) async {
      final rows = await supabase
          .from('race_results')
          .select()
          .eq('race_id', raceId)
          .limit(1);
      return rows.isEmpty ? null : rows.first;
    });

final sprintResultProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, raceId) async {
      final rows = await supabase
          .from('sprint_results')
          .select()
          .eq('race_id', raceId)
          .limit(1);
      return rows.isEmpty ? null : rows.first;
    });

final raceClassificationProvider = FutureProvider.autoDispose
    .family<List<RaceClassificationRow>, String>((ref, raceId) async {
      final rows = await supabase
          .from('race_classifications')
          .select()
          .eq('race_id', raceId)
          .order('position', nullsFirst: false);
      return rows.map((e) => RaceClassificationRow.fromJson(e)).toList();
    });

final sprintClassificationProvider = FutureProvider.autoDispose
    .family<List<RaceClassificationRow>, String>((ref, raceId) async {
      final rows = await supabase
          .from('sprint_classifications')
          .select()
          .eq('race_id', raceId)
          .order('position', nullsFirst: false);
      return rows.map((e) => RaceClassificationRow.fromJson(e)).toList();
    });

class ResultsScreen extends ConsumerWidget {
  final String raceId;
  final String? leagueId;
  final bool sprintMode;
  const ResultsScreen({
    super.key,
    required this.raceId,
    this.leagueId,
    this.sprintMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionKey = PredictionKey(raceId: raceId, leagueId: leagueId);
    final raceAsync = ref.watch(raceProvider(raceId));
    final l = AppLocalizations.of(context);
    final driversAsync = ref.watch(driversProvider);
    final predictionAsync = ref.watch(predictionProvider(predictionKey));
    final sprintPredictionAsync = ref.watch(
      sprintPredictionProvider(predictionKey),
    );
    final resultAsync = ref.watch(
      sprintMode ? sprintResultProvider(raceId) : raceResultProvider(raceId),
    );
    final classificationAsync = ref.watch(
      sprintMode
          ? sprintClassificationProvider(raceId)
          : raceClassificationProvider(raceId),
    );

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
        titleSpacing: 0,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          tooltip: l.back,
          onPressed: () => safeBack(
            context,
            fallbackLocation: leagueId == null
                ? '/calendar'
                : '/leagues/$leagueId',
          ),
        ),
        title: raceAsync.maybeWhen(
          data: (race) => Text(
            sprintMode
                ? l.sprintResultsTitle(race.name)
                : l.resultsTitle(race.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          orElse: () => Text(
            sprintMode ? 'SPRINT RESULTS' : 'RESULTS',
            textAlign: TextAlign.center,
          ),
        ),
        actions: const [SizedBox(width: 56)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: raceAsync.when(
        loading: () => const AppLoadingState(label: 'Results loading'),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(raceProvider(raceId)),
        ),
        data: (race) => driversAsync.when(
          loading: () => const AppLoadingState(label: 'Drivers loading'),
          error: (e, _) => AppErrorState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(driversProvider),
          ),
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
            final sprintPrediction = sprintPredictionAsync.asData?.value;
            final classification =
                classificationAsync.asData?.value ?? const [];

            // Cancel durumu: ana yarış için race.isCancelled, sprint için
            // sprintStatus == cancelled.
            final isCancelled = sprintMode
                ? race.sprintStatus == RaceStatus.cancelled
                : race.isCancelled;
            if (isCancelled) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                children: [_CancelledBanner(note: race.cancellationNote)],
              );
            }

            // Lig bağlamı dışında (ana takvimden açıldığında) sadece
            // resmi yarış sonuçları gösterilir; peoplesel skor / kırılım gizli.
            final showPersonal = leagueId != null;
            final personalScore = sprintMode
                ? sprintPrediction?.score
                : prediction?.score;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: [
                if (showPersonal) ...[
                  if (personalScore != null)
                    _HeroScore(score: personalScore, leagueId: leagueId),
                  const SizedBox(height: 24),
                  _SectionTitle(label: 'POINTS BREAKDOWN'),
                  if (sprintMode)
                    sprintPrediction != null
                        ? _SprintScoreBreakdown(
                            prediction: sprintPrediction,
                            result: result,
                            drivers: drivers,
                          )
                        : const _NoPredictionMsg(sprintMode: true)
                  else if (prediction != null)
                    _ScoreBreakdown(
                      prediction: prediction,
                      result: result,
                      drivers: drivers,
                    )
                  else
                    const _NoPredictionMsg(sprintMode: false),
                  const SizedBox(height: 24),
                ],
                _SectionTitle(label: 'RESULTS'),
                if (result != null)
                  _ActualResults(
                    result: result,
                    drivers: drivers,
                    byId: byId,
                    sprintMode: sprintMode,
                  )
                else
                  const _NoResultYet(),
                if (classification.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(label: 'FULL STANDINGS'),
                  _FullClassification(rows: classification, byId: byId),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroScore extends StatelessWidget {
  final int score;
  final String? leagueId;
  const _HeroScore({required this.score, required this.leagueId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A26), Color(0xFF15151E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F2E), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'YOUR SCORE',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE10600),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PTS',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (leagueId != null) ...[
            const SizedBox(height: 16),
            const Text(
              'League standings are shown on the weekly summary screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D26A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoPredictionMsg extends StatelessWidget {
  final bool sprintMode;

  const _NoPredictionMsg({required this.sprintMode});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A26),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      sprintMode
          ? 'You did not make a prediction for this sprint.'
          : 'You did not make a prediction for this race.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0x99FFFFFF)),
    ),
  );
}

class _SprintScoreBreakdown extends StatelessWidget {
  final SprintPrediction prediction;
  final Map<String, dynamic>? result;
  final List<Driver> drivers;

  const _SprintScoreBreakdown({
    required this.prediction,
    required this.result,
    required this.drivers,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = result == null
        ? const <_BreakdownData>[]
        : _build(context, prediction, result!, drivers);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Text(
              l.sprintPointsBreakdownPending,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF)),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _BreakdownItem(
                label: items[i].label,
                points: items[i].points,
                status: items[i].status,
                note: items[i].note,
              ),
              if (i < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFF15151E), height: 1),
                ),
            ],
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            child: Divider(color: Color(0xFFE10600), thickness: 2, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.total,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              Text(
                '${prediction.score ?? 0} PTS',
                style: const TextStyle(
                  fontSize: 24,
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

  List<_BreakdownData> _build(
    BuildContext context,
    SprintPrediction p,
    Map<String, dynamic> r,
    List<Driver> drivers,
  ) {
    final l = AppLocalizations.of(context);
    String code(String? id) {
      if (id == null) return '-';
      for (final d in drivers) {
        if (d.id == id) return d.code;
      }
      return '-';
    }

    String teamName(String? id) {
      if (id == null) return '-';
      for (final d in drivers) {
        if (d.teamId == id) return d.teamName ?? d.teamCode ?? '-';
      }
      return '-';
    }

    final actualPodiumOrdered = [r['p1'], r['p2'], r['p3']];
    final actualPodium = {r['p1'], r['p2'], r['p3']};
    final predictedPodium = [p.p1Id, p.p2Id, p.p3Id];
    final podiumNames = predictedPodium.whereType<String>().toList();
    final podiumHits = podiumNames.where(actualPodium.contains).length;
    var exactPodiumHits = 0;
    for (var i = 0; i < 3; i++) {
      if (predictedPodium[i] != null &&
          predictedPodium[i] == actualPodiumOrdered[i]) {
        exactPodiumHits++;
      }
    }
    final podiumExact = exactPodiumHits == 3;
    final sprintPodiumPoints =
        podiumHits * 4 + exactPodiumHits * 1 + (podiumExact ? 2 : 0);
    final actualDnf = (r['dnf_count'] as num?)?.toInt();
    final dnfDiff = p.dnfCount == null || actualDnf == null
        ? null
        : (p.dnfCount! - actualDnf).abs();
    final actualSafetyCar = r['safety_car'] as bool?;

    return [
      _BreakdownData(
        label: l.sprintWinnerResult(code(p.winnerDriverId)),
        points: p.winnerDriverId == r['p1'] ? 8 : 0,
        status: p.winnerDriverId == r['p1'] ? 'correct' : 'wrong',
        note: p.winnerDriverId == r['p1']
            ? null
            : '(Correct: ${code(r['p1'] as String?)})',
      ),
      _BreakdownData(
        label: l.sprintPodiumResult(podiumNames.map(code).join(' ')),
        points: sprintPodiumPoints,
        status: podiumExact
            ? 'correct'
            : (podiumHits > 0 ? 'partial' : 'wrong'),
        note:
            '$podiumHits/3 names · $exactPodiumHits/3 position${podiumExact ? ' · perfect bonus' : ''}',
      ),
      _BreakdownData(
        label: 'Team: ${teamName(p.topTeamId)}',
        points: p.topTeamId == r['top_team_id'] ? 8 : 0,
        status: p.topTeamId == r['top_team_id'] ? 'correct' : 'wrong',
        note: p.topTeamId == r['top_team_id']
            ? null
            : '(Correct: ${teamName(r['top_team_id'] as String?)})',
      ),
      _BreakdownData(
        label: 'Sprint pole: ${code(p.poleDriverId)}',
        points: p.poleDriverId == r['pole'] ? 6 : 0,
        status: p.poleDriverId == r['pole'] ? 'correct' : 'wrong',
        note: p.poleDriverId == r['pole']
            ? null
            : '(Correct: ${code(r['pole'] as String?)})',
      ),
      _BreakdownData(
        label: 'Sprint DNF: ${p.dnfCount ?? '-'}',
        points: dnfDiff == 0 ? 4 : (dnfDiff == 1 ? 2 : 0),
        status: dnfDiff == 0 ? 'correct' : (dnfDiff == 1 ? 'partial' : 'wrong'),
        note: actualDnf == null ? null : '(Actual: $actualDnf)',
      ),
      _BreakdownData(
        label:
            'Safety car: ${p.safetyCar == null ? '-' : (p.safetyCar! ? 'Yes' : 'No')}',
        points:
            p.safetyCar != null &&
                actualSafetyCar != null &&
                p.safetyCar == actualSafetyCar
            ? 2
            : 0,
        status: actualSafetyCar == null
            ? 'pending'
            : (p.safetyCar == actualSafetyCar ? 'correct' : 'wrong'),
        note: actualSafetyCar == null
            ? null
            : '(Actual: ${actualSafetyCar ? 'Yes' : 'No'})',
      ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

class _ScoreBreakdown extends StatelessWidget {
  final Prediction prediction;
  final Map<String, dynamic>? result;
  final List<Driver> drivers;

  const _ScoreBreakdown({
    required this.prediction,
    required this.result,
    required this.drivers,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = result == null
        ? const <_BreakdownData>[]
        : _buildBreakdownItems(context, prediction, result!, drivers);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Text(
              l.pointsBreakdownPending,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF)),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _BreakdownItem(
                label: items[i].label,
                points: items[i].points,
                status: items[i].status,
                note: items[i].note,
              ),
              if (i < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFF15151E), height: 1),
                ),
            ],
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            child: Divider(color: Color(0xFFE10600), thickness: 2, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.total,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              Text(
                '${prediction.score ?? 0} PTS',
                style: const TextStyle(
                  fontSize: 24,
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

  List<_BreakdownData> _buildBreakdownItems(
    BuildContext context,
    Prediction prediction,
    Map<String, dynamic> result,
    List<Driver> drivers,
  ) {
    final l = AppLocalizations.of(context);
    String code(String? id) {
      if (id == null) return '-';
      for (final d in drivers) {
        if (d.id == id) return d.code;
      }
      return '-';
    }

    String teamName(String? id) {
      if (id == null) return '-';
      for (final d in drivers) {
        if (d.teamId == id) return d.teamName ?? d.teamCode ?? '-';
      }
      return '-';
    }

    final actualPodium = [result['p1'], result['p2'], result['p3']];
    final predictedPodium = [prediction.p1Id, prediction.p2Id, prediction.p3Id];
    final podiumNames = predictedPodium.whereType<String>().toList();
    final podiumHits = podiumNames
        .where((id) => actualPodium.contains(id))
        .length;
    var exactPodiumHits = 0;
    for (var i = 0; i < 3; i++) {
      if (predictedPodium[i] != null && predictedPodium[i] == actualPodium[i]) {
        exactPodiumHits++;
      }
    }
    final podiumExact = exactPodiumHits == 3;
    final podiumPoints =
        podiumHits * 5 + exactPodiumHits * 2 + (podiumExact ? 3 : 0);
    final actualDnf = (result['dnf_count'] as num?)?.toInt();
    final dnfDiff = prediction.dnfCount == null || actualDnf == null
        ? null
        : (prediction.dnfCount! - actualDnf).abs();
    final actualSafetyCar = result['safety_car'] as bool?;

    return [
      _BreakdownData(
        label: l.winnerBreakdown(code(prediction.winnerDriverId)),
        points: prediction.winnerDriverId == result['p1'] ? 10 : 0,
        status: prediction.winnerDriverId == result['p1'] ? 'correct' : 'wrong',
        note: prediction.winnerDriverId == result['p1']
            ? null
            : '(Correct: ${code(result['p1'] as String?)})',
      ),
      _BreakdownData(
        label: l.podiumBreakdown(podiumNames.map(code).join(' ')),
        points: podiumPoints,
        status: podiumExact
            ? 'correct'
            : (podiumHits > 0 ? 'partial' : 'wrong'),
        note:
            '$podiumHits/3 names · $exactPodiumHits/3 position${podiumExact ? ' · perfect bonus' : ''}',
      ),
      _BreakdownData(
        label: 'Team: ${teamName(prediction.topTeamId)}',
        points: prediction.topTeamId == result['top_team_id'] ? 10 : 0,
        status: prediction.topTeamId == result['top_team_id']
            ? 'correct'
            : 'wrong',
        note: prediction.topTeamId == result['top_team_id']
            ? null
            : '(Correct: ${teamName(result['top_team_id'] as String?)})',
      ),
      _BreakdownData(
        label: 'Pole: ${code(prediction.poleDriverId)}',
        points: prediction.poleDriverId == result['pole'] ? 8 : 0,
        status: prediction.poleDriverId == result['pole'] ? 'correct' : 'wrong',
        note: prediction.poleDriverId == result['pole']
            ? null
            : '(Correct: ${code(result['pole'] as String?)})',
      ),
      _BreakdownData(
        label: 'DNF: ${prediction.dnfCount ?? '-'}',
        points: dnfDiff == 0 ? 6 : (dnfDiff == 1 ? 3 : 0),
        status: dnfDiff == 0 ? 'correct' : (dnfDiff == 1 ? 'partial' : 'wrong'),
        note: actualDnf == null ? null : '(Actual: $actualDnf)',
      ),
      _BreakdownData(
        label:
            'Safety car: ${prediction.safetyCar == null ? '-' : (prediction.safetyCar! ? 'Yes' : 'No')}',
        points:
            prediction.safetyCar != null &&
                actualSafetyCar != null &&
                prediction.safetyCar == actualSafetyCar
            ? 3
            : 0,
        status: actualSafetyCar == null
            ? 'pending'
            : (prediction.safetyCar == actualSafetyCar ? 'correct' : 'wrong'),
        note: actualSafetyCar == null
            ? null
            : '(Actual: ${actualSafetyCar ? 'Yes' : 'No'})',
      ),
      _BreakdownData(
        label: l.jokerResult(prediction.jokerOption ?? '-'),
        points:
            prediction.jokerOption != null &&
                prediction.jokerOption == result['joker_correct']
            ? 12
            : 0,
        status: result['joker_correct'] == null
            ? 'pending'
            : (prediction.jokerOption == result['joker_correct']
                  ? 'correct'
                  : 'wrong'),
        note: result['joker_correct'] == null
            ? null
            : '(Correct: ${result['joker_correct']})',
      ),
    ];
  }
}

class _BreakdownData {
  final String label;
  final int points;
  final String status;
  final String? note;

  const _BreakdownData({
    required this.label,
    required this.points,
    required this.status,
    this.note,
  });
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int points;
  final String status;
  final String? note;

  const _BreakdownItem({
    required this.label,
    required this.points,
    required this.status,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final icon = {
      'correct': '✓',
      'wrong': '✗',
      'partial': '~',
      'pending': '~',
    }[status]!;

    final color = {
      'correct': const Color(0xFF00D26A),
      'wrong': const Color(0xFFFF2D55),
      'partial': const Color(0xFFFF9F1C),
      'pending': const Color(0x66FFFFFF),
    }[status]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          points > 0 ? '+$points' : '$points',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: points > 0
                ? const Color(0xFF00D26A)
                : const Color(0x66FFFFFF),
          ),
        ),
      ],
    );
  }
}

class _ActualResults extends StatelessWidget {
  final Map<String, dynamic> result;
  final List<Driver> drivers;
  final Driver? Function(String?) byId;
  final bool sprintMode;

  const _ActualResults({
    required this.result,
    required this.drivers,
    required this.byId,
    this.sprintMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p1 = byId(result['p1'] as String?);
    final p2 = byId(result['p2'] as String?);
    final p3 = byId(result['p3'] as String?);
    final topTeamName = _teamName(result['top_team_id'] as String?);
    final safetyCar = result['safety_car'] as bool?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _ResultRow(
            label: sprintMode ? l.sprintWinnerResultLabel : l.winnerResultLabel,
            value: p1?.code ?? '—',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF15151E), height: 1),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              sprintMode ? l.sprintPodiumResultLabel : l.podiumResultLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (p1 != null) _PodiumPosition(position: 1, driver: p1),
          if (p2 != null) ...[
            const SizedBox(height: 10),
            _PodiumPosition(position: 2, driver: p2),
          ],
          if (p3 != null) ...[
            const SizedBox(height: 10),
            _PodiumPosition(position: 3, driver: p3),
          ],
          if (p1 == null && p2 == null && p3 == null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('—', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF15151E), height: 1),
          ),
          _ResultRow(label: 'Top scoring team:', value: topTeamName),
          const SizedBox(height: 6),
          _ResultRow(
            label: sprintMode ? l.sprintPoleResultLabel : l.poleResultLabel,
            value: byId(result['pole'] as String?)?.code ?? '—',
          ),
          const SizedBox(height: 6),
          _ResultRow(
            label: 'DNF count:',
            value: '${result['dnf_count'] ?? '—'}',
          ),
          const SizedBox(height: 6),
          _ResultRow(
            label: 'Safety car:',
            value: safetyCar == null ? '—' : (safetyCar ? 'Yes' : 'No'),
          ),
        ],
      ),
    );
  }

  String _teamName(String? id) {
    if (id == null) return '—';
    for (final d in drivers) {
      if (d.teamId == id) return d.teamName ?? d.teamCode ?? '—';
    }
    return '—';
  }
}

class _PodiumPosition extends StatelessWidget {
  final int position;
  final Driver driver;

  const _PodiumPosition({required this.position, required this.driver});

  @override
  Widget build(BuildContext context) {
    final medal = position == 1
        ? '🥇'
        : position == 2
        ? '🥈'
        : '🥉';

    return Row(
      children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: Color(
              int.parse(
                (driver.teamColor ?? '#6E6E80').replaceAll('#', '0xFF'),
              ),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                driver.code,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' · ${driver.fullName.split(' ').last}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  final String? note;
  const _CancelledBanner({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE10600), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, color: Color(0xFFE10600)),
              const SizedBox(width: 8),
              const Text(
                'RACE CANCELED',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note?.isNotEmpty == true
                ? note!
                : 'This race was canceled. Predictions will not be scored.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullClassification extends StatelessWidget {
  final List<RaceClassificationRow> rows;
  final Driver? Function(String?) byId;

  const _FullClassification({required this.rows, required this.byId});

  int _statusOrder(String s) => switch (s) {
    'finished' => 0,
    'dnf' => 1,
    'dsq' => 2,
    'dns' => 3,
    _ => 4,
  };

  @override
  Widget build(BuildContext context) {
    // Önce status grubuna göre, sonra pozisyona (null'lar gruplarının sonuna).
    final sorted = [...rows]
      ..sort((a, b) {
        final s = _statusOrder(a.status).compareTo(_statusOrder(b.status));
        if (s != 0) return s;
        final ap = a.position;
        final bp = b.position;
        if (ap == null && bp == null) return 0;
        if (ap == null) return 1;
        if (bp == null) return -1;
        return ap.compareTo(bp);
      });

    // OpenF1 bazen sınıflandırılmış sürücmembers pozisyon vermez.
    // status='finished' ama position=null olanlara grup içi positionya göre
    // ardışık numara veriyoruz (mevcut maksimum + 1, ...).
    final maxFinishedPos = sorted
        .where((r) => r.status == 'finished' && r.position != null)
        .map((r) => r.position!)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final displayPositions = <int, int?>{};
    var nextFallback = maxFinishedPos;
    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      if (r.status == 'finished') {
        if (r.position != null) {
          displayPositions[i] = r.position;
        } else {
          nextFallback += 1;
          displayPositions[i] = nextFallback;
        }
      } else {
        displayPositions[i] = null;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            _ClassificationRow(
              row: sorted[i],
              driver: byId(sorted[i].driverId),
              displayPosition: displayPositions[i],
            ),
            if (i < sorted.length - 1)
              const Divider(color: Color(0xFF15151E), height: 1),
          ],
        ],
      ),
    );
  }
}

class _ClassificationRow extends StatelessWidget {
  final RaceClassificationRow row;
  final Driver? driver;
  final int? displayPosition;

  const _ClassificationRow({
    required this.row,
    required this.driver,
    required this.displayPosition,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = row.status == 'finished';
    final positionText = isFinished && displayPosition != null
        ? '$displayPosition'
        : row.status.toUpperCase();
    final positionColor = isFinished ? Colors.white : const Color(0xFFFF2D55);

    final teamColor = driver?.teamColor;
    final stripeColor = teamColor != null
        ? Color(int.parse(teamColor.replaceAll('#', '0xFF')))
        : const Color(0xFF6E6E80);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              positionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: positionColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              color: stripeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  driver?.code ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driver?.fullName ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (driver?.teamName != null)
            Text(
              driver!.teamName!.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
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
    child: Center(
      child: Column(
        children: [
          Icon(Icons.hourglass_top, size: 32, color: Color(0x8AFFFFFF)),
          SizedBox(height: 8),
          Text(
            'Official result has not arrived yet',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'It will be pulled automatically from OpenF1 when the race ends.',
            style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
