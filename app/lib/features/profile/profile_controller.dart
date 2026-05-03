import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (row == null) return null;
  return Profile.fromJson(row);
});

Future<void> completeOnboarding({String? username}) async {
  await supabase.rpc('complete_onboarding', params: {'p_username': username});
}

Future<void> requestAccountDeletion({String? reason}) async {
  await supabase.rpc('request_account_deletion', params: {'p_reason': reason});
}

final allBadgesProvider = FutureProvider<List<AppBadge>>((ref) async {
  final rows = await supabase.from('badges').select().order('rarity');
  return rows.map((e) => AppBadge.fromJson(e)).toList();
});

final myBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase
      .from('user_badges')
      .select('*, badge:badges(*)')
      .eq('user_id', user.id)
      .order('awarded_at', ascending: false);
  return rows.map((e) => UserBadge.fromJson(e)).toList();
});

class ProfileStats {
  final int totalScore;
  final int mainScore;
  final int sprintScore;
  final int badgeCount;
  final int eventsPredicted;
  final int mainEventsPredicted;
  final int sprintEventsPredicted;
  final int bestScore;
  final String? bestLeagueName;
  final int bestLeagueScore;
  final List<LeaguePerformance> leaguePerformances;
  final double averageScore;
  ProfileStats({
    required this.totalScore,
    required this.mainScore,
    required this.sprintScore,
    required this.badgeCount,
    required this.eventsPredicted,
    required this.mainEventsPredicted,
    required this.sprintEventsPredicted,
    required this.bestScore,
    required this.bestLeagueName,
    required this.bestLeagueScore,
    required this.leaguePerformances,
    required this.averageScore,
  });
}

class LeaguePerformance {
  final String leagueId;
  final String leagueName;
  final int totalScore;
  final int mainScore;
  final int sprintScore;
  final int scoredEvents;
  final int rank;

  LeaguePerformance({
    required this.leagueId,
    required this.leagueName,
    required this.totalScore,
    required this.mainScore,
    required this.sprintScore,
    required this.scoredEvents,
    required this.rank,
  });
}

class CategoryAccuracy {
  final String category;
  final int correct;
  final int total;
  CategoryAccuracy({
    required this.category,
    required this.correct,
    required this.total,
  });
  double get rate => total == 0 ? 0 : correct / total;
}

class TrendPoint {
  final int round;
  final String raceName;
  final int score;
  TrendPoint({
    required this.round,
    required this.raceName,
    required this.score,
  });
}

class DriverAccuracy {
  final String code;
  final String fullName;
  final String? color;
  final int predicted;
  final int correct;
  DriverAccuracy({
    required this.code,
    required this.fullName,
    required this.color,
    required this.predicted,
    required this.correct,
  });
  double get rate => predicted == 0 ? 0 : correct / predicted;
}

final categoryAccuracyProvider = FutureProvider<List<CategoryAccuracy>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_category_accuracy',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => CategoryAccuracy(
          category: e['category'] as String,
          correct: ((e['correct'] ?? 0) as num).toInt(),
          total: ((e['total'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final seasonTrendProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_season_trend',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => TrendPoint(
          round: (e['round'] as num).toInt(),
          raceName: e['race_name'] as String,
          score: ((e['score'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final driverAccuracyProvider = FutureProvider<List<DriverAccuracy>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_driver_accuracy',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => DriverAccuracy(
          code: e['code'] as String,
          fullName: e['full_name'] as String,
          color: e['color'] as String?,
          predicted: ((e['predicted'] ?? 0) as num).toInt(),
          correct: ((e['correct'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return ProfileStats(
      totalScore: 0,
      mainScore: 0,
      sprintScore: 0,
      badgeCount: 0,
      eventsPredicted: 0,
      mainEventsPredicted: 0,
      sprintEventsPredicted: 0,
      bestScore: 0,
      bestLeagueName: null,
      bestLeagueScore: 0,
      leaguePerformances: const [],
      averageScore: 0,
    );
  }
  final mainPreds = await supabase
      .from('predictions')
      .select('race_id, league_id, score, league:leagues(id, name)')
      .eq('user_id', user.id);
  final sprintPreds = await supabase
      .from('sprint_predictions')
      .select('race_id, league_id, score, league:leagues(id, name)')
      .eq('user_id', user.id);
  final mainBestByEvent = <String, int>{};
  final sprintBestByEvent = <String, int>{};
  final leagueTotals = <String, _LeaguePerformanceAccumulator>{};
  int best = 0;

  void collectScores(
    Iterable<dynamic> rows,
    String mode,
    Map<String, int> bestByEvent,
  ) {
    for (final row in rows) {
      if (row['score'] == null) continue;
      final score = (row['score'] as num).toInt();
      final raceId = row['race_id'] as String;
      final leagueId = row['league_id'] as String?;
      final league = row['league'] as Map<String, dynamic>?;
      final key = '$mode:$raceId';
      final prev = bestByEvent[key];
      if (prev == null || score > prev) {
        bestByEvent[key] = score;
      }
      if (leagueId != null) {
        final current = leagueTotals.putIfAbsent(
          leagueId,
          () => _LeaguePerformanceAccumulator(
            leagueId: leagueId,
            leagueName: (league?['name'] as String?) ?? 'Lig',
          ),
        );
        if (mode == 'main') {
          current.mainScore += score;
        } else {
          current.sprintScore += score;
        }
        current.scoredEvents += 1;
      }
      if (score > best) {
        best = score;
      }
    }
  }

  collectScores(mainPreds, 'main', mainBestByEvent);
  collectScores(sprintPreds, 'sprint', sprintBestByEvent);

  final mainScore = mainBestByEvent.values.fold<int>(
    0,
    (sum, score) => sum + score,
  );
  final sprintScore = sprintBestByEvent.values.fold<int>(
    0,
    (sum, score) => sum + score,
  );
  final total = mainScore + sprintScore;
  final scored = mainBestByEvent.length + sprintBestByEvent.length;
  final leaguePerformances =
      leagueTotals.values.map((e) => e.toPerformance()).toList()..sort((a, b) {
        final score = b.totalScore.compareTo(a.totalScore);
        if (score != 0) return score;
        return a.leagueName.compareTo(b.leagueName);
      });
  final rankedLeaguePerformances = [
    for (var i = 0; i < leaguePerformances.length; i++)
      leaguePerformances[i].copyWith(rank: i + 1),
  ];
  final bestLeague = rankedLeaguePerformances.isEmpty
      ? null
      : rankedLeaguePerformances.first;
  final badges = await supabase
      .from('user_badges')
      .select('id')
      .eq('user_id', user.id);
  return ProfileStats(
    totalScore: total,
    mainScore: mainScore,
    sprintScore: sprintScore,
    badgeCount: badges.length,
    eventsPredicted: scored,
    mainEventsPredicted: mainBestByEvent.length,
    sprintEventsPredicted: sprintBestByEvent.length,
    bestScore: best,
    bestLeagueName: bestLeague?.leagueName,
    bestLeagueScore: bestLeague?.totalScore ?? 0,
    leaguePerformances: rankedLeaguePerformances,
    averageScore: scored == 0 ? 0 : total / scored,
  );
});

class _LeaguePerformanceAccumulator {
  final String leagueId;
  final String leagueName;
  int mainScore = 0;
  int sprintScore = 0;
  int scoredEvents = 0;

  _LeaguePerformanceAccumulator({
    required this.leagueId,
    required this.leagueName,
  });

  LeaguePerformance toPerformance() => LeaguePerformance(
    leagueId: leagueId,
    leagueName: leagueName,
    totalScore: mainScore + sprintScore,
    mainScore: mainScore,
    sprintScore: sprintScore,
    scoredEvents: scoredEvents,
    rank: 0,
  );
}

extension on LeaguePerformance {
  LeaguePerformance copyWith({int? rank}) => LeaguePerformance(
    leagueId: leagueId,
    leagueName: leagueName,
    totalScore: totalScore,
    mainScore: mainScore,
    sprintScore: sprintScore,
    scoredEvents: scoredEvents,
    rank: rank ?? this.rank,
  );
}
