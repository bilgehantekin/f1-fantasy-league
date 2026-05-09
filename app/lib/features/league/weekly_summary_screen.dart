import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error_messages.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import '../prediction/prediction_controller.dart';
import 'league_controller.dart';
import 'weekly_summary_share_card.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String raceId;
  final bool sprintMode;

  const WeeklySummaryScreen({
    super.key,
    required this.leagueId,
    required this.raceId,
    this.sprintMode = false,
  });

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final leagueAsync = ref.watch(leagueProvider(widget.leagueId));
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final summaryKey = WeeklySummaryKey(
      leagueId: widget.leagueId,
      raceId: widget.raceId,
      sprint: widget.sprintMode,
    );
    final summaryAsync = ref.watch(weeklySummaryProvider(summaryKey));

    final league = leagueAsync.asData?.value;
    final race = raceAsync.asData?.value;
    final summary = summaryAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        title: Text(l.weeklySummary),
        actions: [
          IconButton(
            tooltip: l.sharePreview,
            icon: const Icon(Icons.visibility_outlined, size: 21),
            onPressed: (league == null || race == null || summary == null)
                ? null
                : () => _openSharePreview(league, race, summary),
          ),
          IconButton(
            tooltip: l.share,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share, size: 20),
            onPressed: (league == null || race == null || summary == null)
                ? null
                : () => _share(league, race, summary),
          ),
        ],
      ),
      body: Stack(
        children: [
          leagueAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(l.errorWithMessage(friendlyError(e)))),
            data: (league) => raceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l.errorWithMessage(friendlyError(e)))),
              data: (race) => summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(l.errorWithMessage(friendlyError(e)))),
                data: (summary) => _Body(
                  league: league,
                  race: race,
                  summary: summary,
                  sprintMode: widget.sprintMode,
                ),
              ),
            ),
          ),
          if (league != null && race != null && summary != null)
            Positioned(
              left: -1400,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: WeeklySummaryShareCard(
                  league: league,
                  race: race,
                  summary: summary,
                  sprintMode: widget.sprintMode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSharePreview(
    League league,
    Race race,
    LeagueWeeklySummary summary,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _SharePreviewPage(
          league: league,
          race: race,
          summary: summary,
          sprintMode: widget.sprintMode,
          sharing: _sharing,
          onShare: () => _share(league, race, summary),
        ),
      ),
    );
  }

  Future<void> _share(
    League league,
    Race race,
    LeagueWeeklySummary summary,
  ) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final l = AppLocalizations.of(context);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError(l.shareCardCouldNotBePrepared);
      }
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError(l.shareImageCouldNotBeCreated);
      }

      final fileName =
          'gridcall_${league.inviteCode.toLowerCase()}_'
          'r${race.round}'
          '${widget.sprintMode ? '_sprint' : ''}.png';
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject: l.weeklySummarySubject(league.name, race.name),
        text: _shareText(
          AppLocalizations.of(context),
          league.name,
          race.name,
          summary,
        ),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.shareError(friendlyError(e)))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  static String _shareText(
    AppLocalizations l,
    String leagueName,
    String raceName,
    LeagueWeeklySummary summary,
  ) {
    final winner = summary.bestPrediction == null
        ? l.noScoreYet
        : '${summary.bestPrediction!.username} (${summary.bestPrediction!.score} ${l.points})';
    return '$leagueName · $raceName\n${l.winner}: $winner\nGridCall';
  }
}

class _SharePreviewPage extends StatelessWidget {
  final League league;
  final Race race;
  final LeagueWeeklySummary summary;
  final bool sprintMode;
  final bool sharing;
  final Future<void> Function() onShare;

  const _SharePreviewPage({
    required this.league,
    required this.race,
    required this.summary,
    required this.sprintMode,
    required this.sharing,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sharePreview),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).share,
            icon: sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share, size: 20),
            onPressed: sharing ? null : onShare,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            var width = constraints.maxWidth - 28;
            var height = width * 16 / 9;
            final maxHeight = constraints.maxHeight - 28;
            if (height > maxHeight) {
              height = maxHeight;
              width = height * 9 / 16;
            }

            return Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: WeeklySummaryShareCard(
                        league: league,
                        race: race,
                        summary: summary,
                        sprintMode: sprintMode,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final League league;
  final Race race;
  final LeagueWeeklySummary summary;
  final bool sprintMode;

  const _Body({
    required this.league,
    required this.race,
    required this.summary,
    required this.sprintMode,
  });

  @override
  Widget build(BuildContext context) {
    final leagueId = league.id;
    final raceId = race.id;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${league.name.toUpperCase()} · ${AppLocalizations.of(context).raceRoundShort(race.round)}'
          '${sprintMode ? ' · ${AppLocalizations.of(context).sprintUpper}' : ''}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.f1Red,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          race.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: AppLocalizations.of(context).weeklyWinnerLabel,
                value: summary.bestPrediction?.username ?? '-',
                subvalue: summary.bestPrediction == null
                    ? AppLocalizations.of(context).noScoreYet
                    : '${summary.bestPrediction!.score} ${AppLocalizations.of(context).points}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: sprintMode
                    ? AppLocalizations.of(context).predictionsUpper
                    : AppLocalizations.of(context).jokerCorrect,
                value: sprintMode
                    ? '${summary.predictionCount}'
                    : '${summary.jokerHitCount}',
                subvalue: sprintMode
                    ? AppLocalizations.of(context).predictions
                    : AppLocalizations.of(context).people,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: AppLocalizations.of(context).topScoringDriver,
          value: summary.mostPickedDriver?.code ?? '-',
          subvalue: summary.mostPickedDriver == null
              ? AppLocalizations.of(context).noPrediction
              : '${summary.mostPickedDriver!.fullName} · ${summary.mostPickedDriver!.points} ${AppLocalizations.of(context).points}',
          accentColor: summary.mostPickedDriver?.color,
        ),
        const SizedBox(height: 24),
        _SectionTitle(label: AppLocalizations.of(context).topFive),
        const SizedBox(height: 12),
        if (summary.topStandings.isEmpty)
          const _EmptyState()
        else
          for (final row in summary.topStandings)
            _SummaryStandingRow(
              rank: row.rank,
              username: row.username,
              score: row.score,
            ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(
            '/leagues/$leagueId/race/$raceId/results'
            '${sprintMode ? '?mode=sprint' : ''}',
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(AppLocalizations.of(context).viewDetailedResults),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;
  final String? accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subvalue,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor == null
        ? AppColors.f1Red
        : Color(int.parse(accentColor!.replaceAll('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0x99FFFFFF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStandingRow extends StatelessWidget {
  final int rank;
  final String username;
  final int score;

  const _SummaryStandingRow({
    required this.rank,
    required this.username,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.f1Red,
              ),
            ),
          ),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$score ${l.pointsShort}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.f1Red,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      AppLocalizations.of(context).noScoredPredictionsForRace,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0x99FFFFFF)),
    ),
  );
}
