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

class AccountDeletionResult {
  final String requestId;
  final DateTime? scheduledFor;
  const AccountDeletionResult({required this.requestId, this.scheduledFor});
}

Future<AccountDeletionResult> requestAccountDeletion({String? reason}) async {
  final response = await supabase.rpc(
    'request_account_deletion',
    params: {'p_reason': reason},
  );

  final row = _firstRpcRow(response);

  if (row == null) {
    return const AccountDeletionResult(requestId: '');
  }

  return AccountDeletionResult(
    requestId: row['request_id'] as String? ?? '',
    scheduledFor: DateTime.tryParse(row['scheduled_for'] as String? ?? ''),
  );
}

Map<String, dynamic>? _firstRpcRow(Object? response) {
  final Object? rawRow = switch (response) {
    final List<dynamic> rows when rows.isNotEmpty => rows.first,
    final Map<dynamic, dynamic> map => map,
    _ => null,
  };
  if (rawRow is! Map<dynamic, dynamic>) return null;
  return rawRow.map((key, value) => MapEntry(key.toString(), value));
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
  final String? bestEventName;
  final String? bestEventMode;
  final String? bestLeagueName;
  final int bestLeagueScore;
  final List<LeaguePerformance> leaguePerformances;
  final double averageScore;
  final double mainAverageScore;
  final double sprintAverageScore;
  final double weeklyAverageScore;
  final int weeksParticipated;
  final int activeStreak;
  ProfileStats({
    required this.totalScore,
    required this.mainScore,
    required this.sprintScore,
    required this.badgeCount,
    required this.eventsPredicted,
    required this.mainEventsPredicted,
    required this.sprintEventsPredicted,
    required this.bestScore,
    required this.bestEventName,
    required this.bestEventMode,
    required this.bestLeagueName,
    required this.bestLeagueScore,
    required this.leaguePerformances,
    required this.averageScore,
    required this.mainAverageScore,
    required this.sprintAverageScore,
    required this.weeklyAverageScore,
    required this.weeksParticipated,
    required this.activeStreak,
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
      bestEventName: null,
      bestEventMode: null,
      bestLeagueName: null,
      bestLeagueScore: 0,
      leaguePerformances: const [],
      averageScore: 0,
      mainAverageScore: 0,
      sprintAverageScore: 0,
      weeklyAverageScore: 0,
      weeksParticipated: 0,
      activeStreak: 0,
    );
  }
  final mainPreds = await supabase
      .from('predictions')
      .select(
        'race_id, league_id, score, race:races(name, round), league:leagues(id, name)',
      )
      .eq('user_id', user.id);
  final sprintPreds = await supabase
      .from('sprint_predictions')
      .select(
        'race_id, league_id, score, race:races(name, round), league:leagues(id, name)',
      )
      .eq('user_id', user.id);
  final mainBestByEvent = <String, int>{};
  final sprintBestByEvent = <String, int>{};
  final raceNameById = <String, String>{};
  final raceRoundById = <String, int>{};
  final leagueTotals = <String, _LeaguePerformanceAccumulator>{};
  int best = 0;
  String? bestEventName;
  String? bestEventMode;

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
      final race = row['race'] as Map<String, dynamic>?;
      if (race != null) {
        final name = race['name'] as String?;
        if (name != null) raceNameById[raceId] = name;
        final round = race['round'];
        if (round is num) raceRoundById[raceId] = round.toInt();
      }
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
            leagueName: (league?['name'] as String?) ?? 'League',
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
        bestEventName = raceNameById[raceId];
        bestEventMode = mode;
      }
    }
  }

  collectScores(mainPreds, 'main', mainBestByEvent);
  collectScores(sprintPreds, 'sprint', sprintBestByEvent);

  // Bir önceki turda "race" join'i sonradan geldiyse en iyi etkinlik adını
  // tekrar çözmeyi dene.
  if (bestEventName == null && best > 0) {
    for (final entry in mainBestByEvent.entries) {
      if (entry.value == best) {
        final raceId = entry.key.split(':').last;
        bestEventName = raceNameById[raceId];
        bestEventMode = 'main';
        break;
      }
    }
    if (bestEventName == null) {
      for (final entry in sprintBestByEvent.entries) {
        if (entry.value == best) {
          final raceId = entry.key.split(':').last;
          bestEventName = raceNameById[raceId];
          bestEventMode = 'sprint';
          break;
        }
      }
    }
  }

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
  final raceIdsParticipated = <String>{
    ...mainBestByEvent.keys.map((k) => k.split(':').last),
    ...sprintBestByEvent.keys.map((k) => k.split(':').last),
  };
  final weeksParticipated = raceIdsParticipated.length;
  final roundsParticipated =
      raceIdsParticipated
          .map((id) => raceRoundById[id])
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
  int activeStreak = 0;
  if (roundsParticipated.isNotEmpty) {
    activeStreak = 1;
    for (var i = roundsParticipated.length - 1; i > 0; i--) {
      if (roundsParticipated[i] - roundsParticipated[i - 1] == 1) {
        activeStreak++;
      } else {
        break;
      }
    }
  }
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
    bestEventName: bestEventName,
    bestEventMode: bestEventMode,
    bestLeagueName: bestLeague?.leagueName,
    bestLeagueScore: bestLeague?.totalScore ?? 0,
    leaguePerformances: rankedLeaguePerformances,
    averageScore: scored == 0 ? 0 : total / scored,
    mainAverageScore: mainBestByEvent.isEmpty
        ? 0
        : mainScore / mainBestByEvent.length,
    sprintAverageScore: sprintBestByEvent.isEmpty
        ? 0
        : sprintScore / sprintBestByEvent.length,
    weeklyAverageScore: weeksParticipated == 0 ? 0 : total / weeksParticipated,
    weeksParticipated: weeksParticipated,
    activeStreak: activeStreak,
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
