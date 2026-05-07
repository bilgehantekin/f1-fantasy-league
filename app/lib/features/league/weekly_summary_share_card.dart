import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import 'league_controller.dart';
import 'share_card_atoms.dart';

/// Vertical 1080x1920 card suitable for story/feed sharing.
class WeeklySummaryShareCard extends StatelessWidget {
  final League league;
  final Race race;
  final LeagueWeeklySummary summary;
  final bool sprintMode;

  const WeeklySummaryShareCard({
    super.key,
    required this.league,
    required this.race,
    required this.summary,
    required this.sprintMode,
  });

  @override
  Widget build(BuildContext context) {
    final myStanding = summary.myStanding;
    final items = summary.predictionItems;
    final totalPossible = items.fold<int>(
      0,
      (sum, item) => sum + item.maxPoints,
    );
    final memberCount = league.memberCount ?? summary.topStandings.length;
    final topRows = summary.topStandings.take(5).toList();
    final isScored = sprintMode
        ? race.sprintStatus == RaceStatus.finished
        : race.status == RaceStatus.finished;

    return ShareStoryFrame(
      width: 1080,
      height: 1920,
      padding: const EdgeInsets.fromLTRB(78, 130, 78, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShareGridCallLogo(fontSize: 42, bulbSize: 13),
              const Spacer(),
              Text(
                'R${race.round}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 14),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 72),
          Text(
            '${league.name} · $memberCount people',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          _RaceTitle(raceName: race.name, sprintMode: sprintMode),
          const SizedBox(height: 72),
          _ScoreRankBlock(
            row: myStanding,
            isScored: isScored,
            sprintMode: sprintMode,
          ),
          const SizedBox(height: 52),
          Text(
            totalPossible == 0
                ? 'PREDICTIONS'
                : 'PREDICTIONS · ${myStanding?.score ?? 0}/$totalPossible PTS',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            _EmptyPredictionBox(sprintMode: sprintMode, isScored: isScored)
          else
            _PredictionLights(items: items),
          const SizedBox(height: 26),
          _TopThreeRows(rows: topRows, myUserId: summary.myStanding?.userId),
        ],
      ),
    );
  }
}

class _RaceTitle extends StatelessWidget {
  final String raceName;
  final bool sprintMode;

  const _RaceTitle({required this.raceName, required this.sprintMode});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 78,
      fontWeight: FontWeight.w900,
      height: 0.95,
      color: Colors.white,
    );
    if (!sprintMode) {
      return Text(
        raceName.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          raceName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        Text('SPRINT', style: style),
      ],
    );
  }
}

class _ScoreRankBlock extends StatelessWidget {
  final StandingRow? row;
  final bool isScored;
  final bool sprintMode;

  const _ScoreRankBlock({
    required this.row,
    required this.isScored,
    required this.sprintMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(58, 52, 58, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.96),
            AppColors.surfaceHi.withValues(alpha: 0.92),
            AppColors.f1Red.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: row == null
          ? Text(
              isScored
                  ? (sprintMode
                        ? 'You did not make a prediction for this sprint.'
                        : 'You did not make a prediction for this race.')
                  : 'Score has not been calculated yet.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: const Color(0xB3FFFFFF),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${row!.score}',
                            style: const TextStyle(
                              fontSize: 142,
                              fontWeight: FontWeight.w900,
                              height: 0.78,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'PTS',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.52),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RANK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      row!.rank <= 0 ? '-' : '#${row!.rank}',
                      style: const TextStyle(
                        fontSize: 86,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PredictionLights extends StatelessWidget {
  final List<PredictionSummaryItem> items;

  const _PredictionLights({required this.items});

  @override
  Widget build(BuildContext context) {
    final columns = items.length >= 9 ? 5 : 4;
    const gap = 18.0;
    final rows = <List<PredictionSummaryItem>>[
      items.take(columns).toList(),
      items.skip(columns).toList(),
    ].where((row) => row.isNotEmpty).toList();
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(30, 34, 30, 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth =
                      (constraints.maxWidth - (gap * (columns - 1))) / columns;
                  final rowWidth =
                      (slotWidth * rows[i].length) +
                      (gap * (rows[i].length - 1));
                  return Center(
                    child: SizedBox(
                      width: rowWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var j = 0; j < rows[i].length; j++) ...[
                            SizedBox(
                              width: slotWidth,
                              child: _PredictionLight(item: rows[i][j]),
                            ),
                            if (j != rows[i].length - 1)
                              const SizedBox(width: gap),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (i != rows.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _PredictionLight extends StatelessWidget {
  final PredictionSummaryItem item;

  const _PredictionLight({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      'correct' => AppColors.lockGreen,
      'partial' => AppColors.lockOrange,
      _ => AppColors.f1Red,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              colors: [Colors.white.withValues(alpha: 0.82), color, color],
              stops: const [0, 0.38, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.58),
                blurRadius: 22,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _shortLabel(item.label),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            height: 1,
            color: Colors.white.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.points > 0 ? '+${item.points}' : item.value,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: item.points > 0
                ? color
                : Colors.white.withValues(alpha: 0.28),
            height: 1,
          ),
        ),
      ],
    );
  }

  static String _shortLabel(String label) {
    return switch (label) {
      'RACE WINNER' || 'SPRINT WINNER' => 'WINNER',
      'SAFETY CAR' => 'S. CAR',
      'PODIUM P1' || 'PODYUM P1' => 'POD P1',
      'PODIUM P2' || 'PODYUM P2' => 'POD P2',
      'PODIUM P3' || 'PODYUM P3' => 'POD P3',
      'PODIUM BONUS' || 'PODYUM BONUS' => 'POD BONUS',
      'SPRINT POLE' => 'POLE',
      'TOP TEAM' => 'BEST TEAM',
      _ => label,
    };
  }
}

class _TopThreeRows extends StatelessWidget {
  final List<StandingRow> rows;
  final String? myUserId;

  const _TopThreeRows({required this.rows, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'TOP 5',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: row.userId == myUserId
                    ? AppColors.f1Red.withValues(alpha: 0.13)
                    : Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: row.userId == myUserId
                      ? AppColors.f1Red.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.045),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${row.rank}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          row.username,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: row.userId == myUserId
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${row.score}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: row.userId == myUserId
                          ? AppColors.f1Red
                          : Colors.white.withValues(alpha: 0.48),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyPredictionBox extends StatelessWidget {
  final bool sprintMode;
  final bool isScored;

  const _EmptyPredictionBox({required this.sprintMode, required this.isScored});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        isScored
            ? (sprintMode
                  ? 'Because you did not make a sprint prediction, your sprint score and prediction breakdown for this GP cannot be shown.'
                  : 'Because you did not make a prediction, your score and prediction breakdown for this GP cannot be shown.')
            : (sprintMode
                  ? 'Your prediction breakdown will appear here when the sprint result is scored.'
                  : 'Your prediction breakdown will appear here when the race result is scored.'),
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0x99FFFFFF),
        ),
      ),
    );
  }
}
