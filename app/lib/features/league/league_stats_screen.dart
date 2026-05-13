import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/supabase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/premium_stats_icon.dart';
import '../premium/premium_service.dart';
import '../premium/premium_theme.dart';
import 'league_controller.dart';

final leagueUserStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, leagueId) async {
      // The RPC server-side requires the entitlement row in user_entitlements,
      // which is written by the RevenueCat → Supabase webhook. Right after a
      // local purchase the row may not be there yet. Retry a few times so the
      // screen doesn't flash an error while the webhook is in flight.
      const maxAttempts = 6;
      const delay = Duration(milliseconds: 800);
      Object? lastError;
      for (var i = 0; i < maxAttempts; i++) {
        try {
          final res = await supabase.rpc(
            'league_user_overview_stats',
            params: {'p_league_id': leagueId},
          );
          return Map<String, dynamic>.from(res as Map);
        } catch (e) {
          lastError = e;
          if (i < maxAttempts - 1) await Future.delayed(delay);
        }
      }
      throw lastError ?? StateError('league stats failed');
    });

class LeagueStatsScreen extends ConsumerWidget {
  final String leagueId;

  const LeagueStatsScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final premiumEnabled = ref.watch(isPremiumEnabledProvider);
    final isPremium = ref.watch(effectiveIsPremiumProvider);

    return Scaffold(
      backgroundColor: PremiumColors.carbon,
      appBar: AppBar(
        backgroundColor: PremiumColors.carbon,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l.detailedLeagueStats,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(child: PremiumStatsIcon(size: 34)),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: PremiumColors.surfaceHi, width: 1),
        ),
      ),
      body: !premiumEnabled || !isPremium
          ? _LockedStats(
              onUpgrade: premiumEnabled ? () => context.push('/premium') : null,
            )
          : ref
                .watch(leagueProvider(leagueId))
                .when(
                  loading: () => AppLoadingState(label: l.settingsLoading),
                  error: (e, _) => AppErrorState(message: friendlyError(e)),
                  data: (league) => ref
                      .watch(leagueUserStatsProvider(leagueId))
                      .when(
                        loading: () =>
                            AppLoadingState(label: l.settingsLoading),
                        error: (e, _) =>
                            AppErrorState(message: friendlyError(e)),
                        data: (stats) =>
                            _StatsBody(league: league, stats: stats),
                      ),
                ),
    );
  }
}

class _LockedStats extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const _LockedStats({this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppEmptyState(
          icon: Icons.lock_outline,
          title: l.detailedLeagueStats,
          message: l.lockedPremiumStats,
        ),
        const SizedBox(height: 12),
        if (onUpgrade != null)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.gold,
                foregroundColor: PremiumColors.goldOnText,
                elevation: 0,
                side: BorderSide(color: PremiumColors.goldBorder(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                l.upgradeToPremium,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsBody extends StatelessWidget {
  final League league;
  final Map<String, dynamic> stats;

  const _StatsBody({required this.league, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rounds = _roundsFromStats(stats);
    final totalPoints = _asInt(stats['total_points']);
    final rank = _asInt(stats['current_rank']);
    final average = _asDouble(stats['average_points']);
    final completedRounds = _asInt(stats['completed_rounds']);
    final totalRounds = _asInt(stats['total_rounds']);
    final memberCount = _asInt(stats['member_count']);
    final leaderGap = _asInt(stats['leader_gap']);
    final leagueAverage = _asDouble(stats['league_average_points']);
    final leaderScore = _asInt(stats['leader_score']);
    final lowestScore = _asInt(stats['lowest_score']);
    final best = rounds.isEmpty
        ? _roundFromMap(stats['best_weekend'], leagueAverage)
        : rounds.reduce((a, b) => a.you > b.you ? a : b);
    final worst = rounds.isEmpty
        ? _roundFromMap(stats['worst_weekend'], leagueAverage)
        : rounds.reduce((a, b) => a.you < b.you ? a : b);

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _LeagueHero(
          league: league,
          rank: rank,
          memberCount: memberCount,
          completedRounds: completedRounds,
          totalRounds: totalRounds,
          totalPoints: totalPoints,
          leaderGap: leaderGap,
        ),
        const SizedBox(height: 20),
        _KpiSection(
          totalPoints: totalPoints,
          average: average,
          leagueAverage: leagueAverage,
        ),
        const SizedBox(height: 24),
        if (rounds.length >= 2) ...[
          _Section(
            title: l.statsPerformanceTrend,
            right: Row(
              children: [
                _LegendDot(color: PremiumColors.f1Red, label: l.you),
                const SizedBox(width: 12),
                _LegendDot(
                  color: Colors.white.withValues(alpha: 0.35),
                  label: l.statsLeagueAverageShort,
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 340 / 130,
              child: CustomPaint(painter: _TrendPainter(rounds)),
            ),
          ),
          const SizedBox(height: 24),
          _RecentFormSection(rounds: rounds, best: best, worst: worst),
          const SizedBox(height: 24),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState(
              icon: Icons.query_stats,
              title: l.statsNotEnoughDataTitle,
              message: l.statsNotEnoughDataBody,
            ),
          ),
        if (best != null && worst != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(l.statsBestWorst),
                Row(
                  children: [
                    Expanded(child: _BestWorstCard(round: best, isBest: true)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BestWorstCard(round: worst, isBest: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        _Section(
          title: l.statsLeaguePosition,
          child: _PositionSummary(
            totalPoints: totalPoints,
            leagueAverage: leagueAverage,
            leaderScore: leaderScore,
            lowestScore: lowestScore,
          ),
        ),
      ],
    );
  }
}

class _LeagueHero extends StatelessWidget {
  final League league;
  final int rank;
  final int memberCount;
  final int completedRounds;
  final int totalRounds;
  final int totalPoints;
  final int leaderGap;

  const _LeagueHero({
    required this.league,
    required this.rank,
    required this.memberCount,
    required this.completedRounds,
    required this.totalRounds,
    required this.totalPoints,
    required this.leaderGap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final members = memberCount == 0 ? league.memberCount ?? 0 : memberCount;
    final raceTotal = totalRounds == 0 ? completedRounds : totalRounds;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PremiumColors.surfaceLow, PremiumColors.carbon],
        ),
        border: Border(
          bottom: BorderSide(color: PremiumColors.surfaceHi, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(),
          const SizedBox(height: 6),
          Text(
            league.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.statsWeekendProgress(members, completedRounds, raceTotal),
            style: const TextStyle(fontSize: 12, color: Color(0x8CFFFFFF)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: PremiumColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PremiumColors.surfaceHi),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.statsYourRankLabel, style: _smallLabel),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '#$rank',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: PremiumColors.f1Red,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/$members',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0x80FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 44, color: PremiumColors.surfaceHi),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ValueLine(label: l.totalPoints, value: '$totalPoints'),
                      const SizedBox(height: 4),
                      _LeaderGapLine(leaderGap: leaderGap),
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

class _KpiSection extends StatelessWidget {
  final int totalPoints;
  final double average;
  final double leagueAverage;

  const _KpiSection({
    required this.totalPoints,
    required this.average,
    required this.leagueAverage,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final delta = totalPoints - leagueAverage.round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(l.statsSeasonSummary),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: l.statsTotalShort,
                  value: '$totalPoints',
                  sub: l.statsPointsUnit,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _KpiCard(
                  label: l.statsAverageShort,
                  value: average.toStringAsFixed(1),
                  sub: l.statsPointsUnit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PremiumColors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PremiumColors.surfaceHi),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.leagueAverage, style: _smallLabel),
                      const SizedBox(height: 2),
                      Text(
                        l.statsPoints(leagueAverage.toStringAsFixed(1)),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _DeltaChip(delta: delta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFormSection extends StatelessWidget {
  final List<RoundResult> rounds;
  final RoundResult? best;
  final RoundResult? worst;

  const _RecentFormSection({
    required this.rounds,
    required this.best,
    required this.worst,
  });

  @override
  Widget build(BuildContext context) {
    final visible = rounds.length > 5
        ? rounds.sublist(rounds.length - 5)
        : rounds;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(AppLocalizations.of(context).statsRecentWeekends),
          Row(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                Expanded(
                  child: _FormCard(
                    round: visible[i],
                    isBest: visible[i] == best,
                    isWorst: visible[i] == worst,
                  ),
                ),
                if (i < visible.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? right;

  const _Section({required this.title, required this.child, this.right});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title, right: right),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: PremiumColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PremiumColors.surfaceHi),
          ),
          child: child,
        ),
      ],
    ),
  );
}

class RoundResult {
  const RoundResult({
    required this.gp,
    required this.short,
    required this.you,
    required this.leagueAvg,
    required this.position,
  });

  final String gp;
  final String short;
  final int you;
  final int leagueAvg;
  final int position;
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 16,
        decoration: BoxDecoration(
          color: PremiumColors.f1Red,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(AppLocalizations.of(context).statsLeagueLabel, style: _smallLabel),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Widget? right;

  const _SectionTitle(this.text, {this.right});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: PremiumColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
        ?right,
      ],
    ),
  );
}

class _ValueLine extends StatelessWidget {
  final String label;
  final String value;

  const _ValueLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
      children: [
        TextSpan(text: '$label: '),
        TextSpan(
          text: value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _LeaderGapLine extends StatelessWidget {
  final int leaderGap;

  const _LeaderGapLine({required this.leaderGap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLeader = leaderGap <= 0;
    return Row(
      children: [
        Icon(
          isLeader ? Icons.emoji_events_outlined : Icons.arrow_upward_rounded,
          size: 14,
          color: isLeader ? PremiumColors.gold : const Color(0xFFFF2D55),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
              children: isLeader
                  ? [
                      TextSpan(
                        text: l.statsYouAreLeader,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ]
                  : [
                      TextSpan(text: l.statsLeaderGapPrefix),
                      TextSpan(
                        text: l.statsPoints('$leaderGap'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: l.statsLeaderGapSuffix),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool highlight;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
    decoration: BoxDecoration(
      color: PremiumColors.surfaceLow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: highlight
            ? PremiumColors.goldBorder(0.33)
            : PremiumColors.surfaceHi,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _smallLabel),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: highlight ? PremiumColors.gold : Colors.white,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0x80FFFFFF),
          ),
        ),
      ],
    ),
  );
}

class _DeltaChip extends StatelessWidget {
  final int delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color = positive ? const Color(0xFF00D26A) : const Color(0xFFFF2D55);
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            l.statsSignedPoints('${positive ? '+' : ''}$delta'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0x8CFFFFFF),
        ),
      ),
    ],
  );
}

class _FormCard extends StatelessWidget {
  final RoundResult round;
  final bool isBest;
  final bool isWorst;

  const _FormCard({
    required this.round,
    required this.isBest,
    required this.isWorst,
  });

  @override
  Widget build(BuildContext context) {
    final tone = isBest
        ? PremiumColors.gold
        : isWorst
        ? const Color(0xFFFF2D55)
        : Colors.white;
    final border = isBest
        ? PremiumColors.goldBorder(0.33)
        : isWorst
        ? const Color(0xFFFF2D55).withValues(alpha: 0.27)
        : PremiumColors.surfaceHi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: PremiumColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(flagFor(round.gp), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            round.short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0x8CFFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${round.you}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: tone,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'P${round.position}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0x66FFFFFF),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestWorstCard extends StatelessWidget {
  final RoundResult round;
  final bool isBest;

  const _BestWorstCard({required this.round, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = isBest ? PremiumColors.gold : const Color(0xFFFF2D55);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBest
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                isBest ? l.statsBestShort : l.statsWorstShort,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.statsPoints('${round.you}'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            round.gp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.statsLeagueAvgAndPosition(round.leagueAvg, round.position),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0x80FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionSummary extends StatelessWidget {
  final int totalPoints;
  final double leagueAverage;
  final int leaderScore;
  final int lowestScore;

  const _PositionSummary({
    required this.totalPoints,
    required this.leagueAverage,
    required this.leaderScore,
    required this.lowestScore,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Range = lowest scoring user → highest scoring user. When everyone has
    // the same score (or nobody has scored) we collapse to a single point and
    // pin the marker to the middle so the bar still looks balanced.
    final lo = lowestScore.toDouble();
    final hi = leaderScore.toDouble();
    final range = hi - lo;
    final flat = range <= 0;

    double normalize(double value) {
      if (flat) return 0.5;
      return ((value - lo) / range).clamp(0.0, 1.0);
    }

    final youProgress = normalize(totalPoints.toDouble());
    final avgProgress = normalize(leagueAverage);
    final delta = totalPoints - leagueAverage.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const barTop = 28.0;
              const barHeight = 10.0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // YOU label — always above the bar, horizontally centered
                  // on the marker via FractionalTranslation(-0.5, 0).
                  Positioned(
                    left: width * youProgress,
                    top: 6,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        l.statsYouMarker,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: PremiumColors.gold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  // Full gradient bar (always end-to-end coloured)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barTop,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        height: barHeight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PremiumColors.f1Red,
                              PremiumColors.gold,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // League avg vertical line
                  Positioned(
                    left: (width * avgProgress - 1).clamp(0, width - 2),
                    top: barTop - 6,
                    child: Container(
                      width: 2,
                      height: barHeight + 12,
                      color: const Color(0x80FFFFFF),
                    ),
                  ),
                  // YOU dot — colour samples the gradient at the user's
                  // position so the marker blends with the bar underneath.
                  Positioned(
                    left: (width * youProgress - 9).clamp(0, width - 18),
                    top: barTop - 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          PremiumColors.f1Red,
                          PremiumColors.gold,
                          youProgress,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PremiumColors.carbon,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  // League avg label — always BELOW the bar so it never
                  // collides with the YOU label, centered on the avg line.
                  Positioned(
                    left: width * avgProgress,
                    top: barTop + barHeight + 6,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        l.statsLeagueAverageShort,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0x8CFFFFFF),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          delta >= 0
              ? l.statsAheadOfLeagueAverage(delta)
              : l.statsBehindLeagueAverage(delta.abs()),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xA6FFFFFF),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<RoundResult> rounds;

  _TrendPainter(this.rounds);

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 22.0;
    const padR = 8.0;
    const padT = 12.0;
    const padB = 22.0;
    final innerW = size.width - padL - padR;
    final innerH = size.height - padT - padB;
    final maxV =
        rounds
            .map((r) => r.you > r.leagueAvg ? r.you : r.leagueAvg)
            .reduce((a, b) => a > b ? a : b) *
        1.15;

    double x(int i) => padL + innerW * i / (rounds.length - 1);
    double y(num v) => padT + innerH - innerH * v / maxV;

    final grid = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1;
    final textStyle = const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: Color(0x59FFFFFF),
    );

    for (final p in [0.0, 0.5, 1.0]) {
      final yy = padT + innerH * p;
      canvas.drawLine(Offset(padL, yy), Offset(size.width - padR, yy), grid);
      final tp = TextPainter(
        text: TextSpan(text: '${(maxV * (1 - p)).round()}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, yy - 6));
    }

    final avgPath = Path();
    for (var i = 0; i < rounds.length; i++) {
      final point = Offset(x(i), y(rounds[i].leagueAvg));
      i == 0
          ? avgPath.moveTo(point.dx, point.dy)
          : avgPath.lineTo(point.dx, point.dy);
    }
    _drawDashed(
      canvas,
      avgPath,
      Paint()
        ..color = const Color(0x59FFFFFF)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    final youPath = Path();
    for (var i = 0; i < rounds.length; i++) {
      final point = Offset(x(i), y(rounds[i].you));
      i == 0
          ? youPath.moveTo(point.dx, point.dy)
          : youPath.lineTo(point.dx, point.dy);
    }
    final areaPath = Path.from(youPath)
      ..lineTo(x(rounds.length - 1), padT + innerH)
      ..lineTo(padL, padT + innerH)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x52E10600), Color(0x00E10600)],
        ).createShader(Rect.fromLTWH(0, padT, size.width, innerH)),
    );
    canvas.drawPath(
      youPath,
      Paint()
        ..color = PremiumColors.f1Red
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < rounds.length; i++) {
      final center = Offset(x(i), y(rounds[i].you));
      canvas.drawCircle(center, 3.5, Paint()..color = PremiumColors.carbon);
      canvas.drawCircle(
        center,
        3.5,
        Paint()
          ..color = PremiumColors.f1Red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      final tp = TextPainter(
        text: TextSpan(text: rounds[i].short, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, size.height - tp.height - 2),
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => oldDelegate.rounds != rounds;
}

const _smallLabel = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.7,
  color: Color(0x80FFFFFF),
);

List<RoundResult> _roundsFromStats(Map<String, dynamic> stats) {
  final trend = (stats['trend'] as List?) ?? const [];
  return [
    for (var i = 0; i < trend.length; i++)
      if (trend[i] is Map)
        RoundResult(
          gp: '${(trend[i] as Map)['race_name'] ?? ''}',
          short: _shortRaceName('${(trend[i] as Map)['race_name'] ?? ''}', i),
          you: _asInt((trend[i] as Map)['score']),
          leagueAvg: _asInt((trend[i] as Map)['league_avg']),
          position: _asInt((trend[i] as Map)['position']),
        ),
  ];
}

RoundResult? _roundFromMap(Object? value, double leagueAverage) {
  if (value is! Map || value.isEmpty) return null;
  final map = Map<String, dynamic>.from(value);
  final raceName = '${map['race_name'] ?? ''}';
  return RoundResult(
    gp: raceName,
    short: _shortRaceName(raceName, 0),
    you: _asInt(map['score']),
    leagueAvg: _asInt(map['league_avg']) == 0
        ? leagueAverage.round()
        : _asInt(map['league_avg']),
    position: _asInt(map['position']).clamp(1, 99),
  );
}

String _shortRaceName(String raceName, int index) {
  final cleaned = raceName
      .replaceAll(RegExp(r'\bGrand Prix\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bSprint\b', caseSensitive: false), '')
      .trim();
  final parts = cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  final source = parts.isEmpty ? 'R${index + 1}' : parts.first;
  return source.length <= 3
      ? source.toUpperCase()
      : source.substring(0, 3).toUpperCase();
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
