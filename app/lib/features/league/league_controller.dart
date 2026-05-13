import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final myLeaguesProvider = FutureProvider<List<League>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase
      .from('leagues')
      .select('*, league_memberships!inner(user_id)')
      .eq('league_memberships.user_id', user.id);
  final leagues = rows.map((e) => League.fromJson(e)).toList();
  final favoriteIds = await _favoriteLeagueIds(user.id);

  final hydrated = await Future.wait(
    leagues.map((league) async {
      final members = await supabase
          .from('league_memberships')
          .select('user_id')
          .eq('league_id', league.id);
      final standings = await supabase.rpc(
        'league_season_standings',
        params: {'p_league_id': league.id, 'p_season_id': Env.seasonId},
      );
      int? myRank;
      for (final row in standings as List) {
        final data = row as Map<String, dynamic>;
        if (data['user_id'] == user.id) {
          myRank = (data['rnk'] as num).toInt();
          break;
        }
      }
      return league.copyWith(
        memberCount: members.length,
        myRank: myRank,
        isFavorite: favoriteIds.contains(league.id),
      );
    }),
  );
  hydrated.sort(compareLeaguesForMyLeagues);
  return hydrated;
});

int compareLeaguesForMyLeagues(League a, League b) {
  if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

final leagueProvider = FutureProvider.family<League, String>((ref, id) async {
  final user = ref.watch(currentUserProvider);
  final row = await supabase.from('leagues').select().eq('id', id).single();
  final members = await supabase
      .from('league_memberships')
      .select('user_id')
      .eq('league_id', id);
  final favoriteIds = user == null
      ? <String>{}
      : await _favoriteLeagueIds(user.id);
  return League.fromJson(
    row,
  ).copyWith(memberCount: members.length, isFavorite: favoriteIds.contains(id));
});

final seasonStandingsProvider =
    FutureProvider.autoDispose.family<List<StandingRow>, String>((
      ref,
      leagueId,
    ) async {
      final rows = await supabase.rpc(
        'league_season_standings',
        params: {'p_league_id': leagueId, 'p_season_id': Env.seasonId},
      );
      return (rows as List)
          .map((e) => StandingRow.season(e as Map<String, dynamic>))
          .toList();
    });

final previousSeasonStandingsProvider =
    FutureProvider.autoDispose.family<List<StandingRow>, PreviousStandingsKey>((
      ref,
      key,
    ) async {
      final rows = await supabase.rpc(
        'league_season_standings_before',
        params: {
          'p_league_id': key.leagueId,
          'p_season_id': Env.seasonId,
          'p_cutoff': key.cutoff.toUtc().toIso8601String(),
        },
      );
      return (rows as List)
          .map((e) => StandingRow.season(e as Map<String, dynamic>))
          .toList();
    });

final weeklyStandingsProvider =
    FutureProvider.autoDispose.family<List<StandingRow>, WeeklySummaryKey>((
      ref,
      key,
    ) async {
      final rows = await supabase.rpc(
        'league_weekly_standings',
        params: {
          'p_league_id': key.leagueId,
          'p_race_id': key.raceId,
          'p_sprint': key.sprint,
        },
      );
      return (rows as List)
          .map((e) => StandingRow.weekly(e as Map<String, dynamic>))
          .toList();
    });

final weeklyWeekendStandingsProvider =
    FutureProvider.autoDispose.family<List<StandingRow>, WeeklySummaryKey>((
      ref,
      key,
    ) async {
      final results = await Future.wait([
        supabase.rpc(
          'league_weekly_standings',
          params: {
            'p_league_id': key.leagueId,
            'p_race_id': key.raceId,
            'p_sprint': false,
          },
        ),
        supabase.rpc(
          'league_weekly_standings',
          params: {
            'p_league_id': key.leagueId,
            'p_race_id': key.raceId,
            'p_sprint': true,
          },
        ),
      ]);

      final scoresByUser = <String, ({String username, int score})>{};
      final premiumByUser = <String, bool>{};
      for (final result in results) {
        for (final item in result as List) {
          final row = StandingRow.weekly(item as Map<String, dynamic>);
          final current = scoresByUser[row.userId];
          scoresByUser[row.userId] = (
            username: row.username,
            score: (current?.score ?? 0) + row.score,
          );
          premiumByUser[row.userId] =
              premiumByUser[row.userId] == true || row.isPremium;
        }
      }

      final sorted = scoresByUser.entries.toList()
        ..sort((a, b) {
          final score = b.value.score.compareTo(a.value.score);
          if (score != 0) return score;
          return a.value.username.toLowerCase().compareTo(
            b.value.username.toLowerCase(),
          );
        });

      final rows = <StandingRow>[];
      for (var i = 0; i < sorted.length; i++) {
        final entry = sorted[i];
        rows.add(
          StandingRow(
            userId: entry.key,
            username: entry.value.username,
            score: entry.value.score,
            rank: i + 1,
            isPremium: premiumByUser[entry.key] ?? false,
          ),
        );
      }
      return rows;
    });

final leagueMembersProvider = FutureProvider.family<List<LeagueMember>, String>(
  (ref, leagueId) async {
    final rows = await supabase.rpc(
      'league_members',
      params: {'p_league_id': leagueId},
    );
    return (rows as List)
        .map((e) => LeagueMember.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

final weeklySummaryProvider = FutureProvider.autoDispose
    .family<LeagueWeeklySummary, WeeklySummaryKey>((ref, key) async {
      final res = await supabase.rpc(
        'league_weekly_summary',
        params: {
          'p_league_id': key.leagueId,
          'p_race_id': key.raceId,
          'p_sprint': key.sprint,
        },
      );
      return LeagueWeeklySummary.fromJson(res as Map<String, dynamic>);
    });

final weeklyWeekendSummaryProvider = FutureProvider.autoDispose
    .family<LeagueWeeklySummary, WeeklySummaryKey>((ref, key) async {
      final results = await Future.wait([
        supabase.rpc(
          'league_weekly_summary',
          params: {
            'p_league_id': key.leagueId,
            'p_race_id': key.raceId,
            'p_sprint': false,
          },
        ),
        supabase.rpc(
          'league_weekly_summary',
          params: {
            'p_league_id': key.leagueId,
            'p_race_id': key.raceId,
            'p_sprint': true,
          },
        ),
      ]);
      return LeagueWeeklySummary.combine(
        results
            .map(
              (res) =>
                  LeagueWeeklySummary.fromJson(res as Map<String, dynamic>),
            )
            .toList(),
      );
    });

final leaguePredictionStatusProvider =
    FutureProvider.family<LeaguePredictionStatus, String>((
      ref,
      leagueId,
    ) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return const LeaguePredictionStatus.empty();

      final mainRows = await supabase
          .from('predictions')
          .select('race_id')
          .eq('user_id', user.id)
          .eq('league_id', leagueId);
      final sprintRows = await supabase
          .from('sprint_predictions')
          .select('race_id')
          .eq('user_id', user.id)
          .eq('league_id', leagueId);

      return LeaguePredictionStatus(
        mainRaceIds: mainRows.map((e) => e['race_id'] as String).toSet(),
        sprintRaceIds: sprintRows.map((e) => e['race_id'] as String).toSet(),
      );
    });

Future<String> createLeague(String name) async {
  final res = await supabase.rpc(
    'create_league',
    params: {'p_name': name, 'p_season_id': Env.seasonId},
  );
  return res as String;
}

Future<String> joinLeagueByCode(String code) async {
  final res = await supabase.rpc(
    'join_league_by_code',
    params: {'p_code': normalizeInviteCode(code)},
  );
  return res as String;
}

String normalizeInviteCode(String code) => code.trim().toUpperCase();

Future<void> updateLeagueName(String leagueId, String name) async {
  await supabase.rpc(
    'update_league_name',
    params: {'p_league_id': leagueId, 'p_name': name},
  );
}

Future<String> regenerateLeagueInviteCode(String leagueId) async {
  final res = await supabase.rpc(
    'regenerate_league_invite_code',
    params: {'p_league_id': leagueId},
  );
  return res as String;
}

Future<void> removeLeagueMember(String leagueId, String userId) async {
  await supabase.rpc(
    'remove_league_member',
    params: {'p_league_id': leagueId, 'p_user_id': userId},
  );
}

Future<void> transferLeagueOwnership(String leagueId, String newOwnerId) async {
  await supabase.rpc(
    'transfer_league_ownership',
    params: {'p_league_id': leagueId, 'p_new_owner_id': newOwnerId},
  );
}

Future<void> leaveLeague(String leagueId) async {
  await supabase.rpc('leave_league', params: {'p_league_id': leagueId});
}

Future<void> deleteLeague(String leagueId) async {
  await supabase.from('leagues').delete().eq('id', leagueId);
}

Future<bool> setLeagueFavorite(String leagueId, bool favorite) async {
  final res = await supabase.rpc(
    'set_league_favorite',
    params: {'p_league_id': leagueId, 'p_favorite': favorite},
  );
  return res == true;
}

Future<Set<String>> _favoriteLeagueIds(String userId) async {
  try {
    final rows = await supabase
        .from('league_favorites')
        .select('league_id')
        .eq('user_id', userId);
    return rows.map((e) => e['league_id'] as String).toSet();
  } catch (_) {
    return {};
  }
}

class LeagueMember {
  final String userId;
  final String username;
  final String role;
  final DateTime joinedAt;
  final bool isPremium;

  LeagueMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
    this.isPremium = false,
  });

  factory LeagueMember.fromJson(Map<String, dynamic> j) => LeagueMember(
    userId: j['user_id'] as String,
    username: j['username'] as String,
    role: j['role'] as String,
    joinedAt: DateTime.parse(j['joined_at'] as String),
    isPremium: (j['is_premium'] as bool?) ?? false,
  );
}

class WeeklySummaryKey {
  final String leagueId;
  final String raceId;
  final bool sprint;

  const WeeklySummaryKey({
    required this.leagueId,
    required this.raceId,
    this.sprint = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklySummaryKey &&
          leagueId == other.leagueId &&
          raceId == other.raceId &&
          sprint == other.sprint;

  @override
  int get hashCode => Object.hash(leagueId, raceId, sprint);
}

class PreviousStandingsKey {
  final String leagueId;
  final DateTime cutoff;

  const PreviousStandingsKey({required this.leagueId, required this.cutoff});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviousStandingsKey &&
          leagueId == other.leagueId &&
          cutoff == other.cutoff;

  @override
  int get hashCode => Object.hash(leagueId, cutoff);
}

class LeaguePredictionStatus {
  final Set<String> mainRaceIds;
  final Set<String> sprintRaceIds;

  const LeaguePredictionStatus({
    required this.mainRaceIds,
    required this.sprintRaceIds,
  });

  const LeaguePredictionStatus.empty()
    : mainRaceIds = const {},
      sprintRaceIds = const {};

  bool savedFor(String raceId, {required bool sprint}) =>
      sprint ? sprintRaceIds.contains(raceId) : mainRaceIds.contains(raceId);
}

class LeagueWeeklySummary {
  final StandingRow? bestPrediction;
  final StandingRow? myStanding;
  final int jokerHitCount;
  final SummaryDriver? mostPickedDriver;
  final List<StandingRow> topStandings;
  final int predictionCount;
  final List<PredictionSummaryItem> predictionItems;

  LeagueWeeklySummary({
    required this.bestPrediction,
    required this.myStanding,
    required this.jokerHitCount,
    required this.mostPickedDriver,
    required this.topStandings,
    required this.predictionCount,
    required this.predictionItems,
  });

  factory LeagueWeeklySummary.fromJson(Map<String, dynamic> j) {
    final best = j['best_prediction'] as Map<String, dynamic>? ?? {};
    final mine = j['my_standing'] as Map<String, dynamic>? ?? {};
    final mostPicked = j['most_picked_driver'] as Map<String, dynamic>? ?? {};
    final rows = (j['top_standings'] as List? ?? [])
        .map(
          (e) => StandingRow(
            userId: e['user_id'] as String,
            username: e['username'] as String,
            score: ((e['score'] ?? 0) as num).toInt(),
            rank: ((e['rank'] ?? 0) as num).toInt(),
          ),
        )
        .toList();
    final predictionItems = (j['prediction_items'] as List? ?? [])
        .map((e) => PredictionSummaryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return LeagueWeeklySummary(
      bestPrediction: best['user_id'] == null
          ? null
          : StandingRow(
              userId: best['user_id'] as String,
              username: best['username'] as String,
              score: ((best['score'] ?? 0) as num).toInt(),
              rank: ((best['rank'] ?? 1) as num).toInt(),
            ),
      myStanding: mine['user_id'] == null
          ? null
          : StandingRow(
              userId: mine['user_id'] as String,
              username: mine['username'] as String,
              score: ((mine['score'] ?? 0) as num).toInt(),
              rank: ((mine['rank'] ?? 0) as num).toInt(),
            ),
      jokerHitCount: ((j['joker_hit_count'] ?? 0) as num).toInt(),
      mostPickedDriver: mostPicked['id'] == null
          ? null
          : SummaryDriver.fromJson(mostPicked),
      topStandings: rows,
      predictionCount: ((j['prediction_count'] ?? 0) as num).toInt(),
      predictionItems: predictionItems,
    );
  }

  factory LeagueWeeklySummary.combine(List<LeagueWeeklySummary> summaries) {
    final scoresByUser = <String, ({String username, int score})>{};
    final driversById =
        <String, ({SummaryDriver driver, int points, int pickCount})>{};
    var predictionCount = 0;
    var jokerHitCount = 0;
    StandingRow? myStandingSeed;
    var myScore = 0;
    List<PredictionSummaryItem> predictionItems = const [];

    for (final summary in summaries) {
      predictionCount += summary.predictionCount;
      jokerHitCount += summary.jokerHitCount;
      if (summary.myStanding != null) {
        myStandingSeed ??= summary.myStanding;
        myScore += summary.myStanding!.score;
      }
      if (predictionItems.isEmpty && summary.predictionItems.isNotEmpty) {
        predictionItems = summary.predictionItems;
      }
      final picked = summary.mostPickedDriver;
      if (picked != null) {
        final current = driversById[picked.id];
        driversById[picked.id] = (
          driver: picked,
          points: (current?.points ?? 0) + picked.points,
          pickCount: (current?.pickCount ?? 0) + picked.pickCount,
        );
      }
      for (final row in summary.topStandings) {
        final current = scoresByUser[row.userId];
        scoresByUser[row.userId] = (
          username: row.username,
          score: (current?.score ?? 0) + row.score,
        );
      }
    }

    final sorted = scoresByUser.entries.toList()
      ..sort((a, b) {
        final score = b.value.score.compareTo(a.value.score);
        if (score != 0) return score;
        return a.value.username.toLowerCase().compareTo(
          b.value.username.toLowerCase(),
        );
      });

    final rows = <StandingRow>[];
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      rows.add(
        StandingRow(
          userId: entry.key,
          username: entry.value.username,
          score: entry.value.score,
          rank: i + 1,
        ),
      );
    }

    StandingRow? myStanding;
    if (myStandingSeed != null) {
      final matched = rows.where((row) => row.userId == myStandingSeed!.userId);
      myStanding = matched.isEmpty
          ? StandingRow(
              userId: myStandingSeed.userId,
              username: myStandingSeed.username,
              score: myScore,
              rank: 0,
            )
          : matched.first;
    }

    SummaryDriver? bestDriver;
    if (driversById.isNotEmpty) {
      final best = driversById.values.toList()
        ..sort((a, b) {
          final points = b.points.compareTo(a.points);
          if (points != 0) return points;
          final picks = b.pickCount.compareTo(a.pickCount);
          if (picks != 0) return picks;
          return a.driver.code.compareTo(b.driver.code);
        });
      final top = best.first;
      bestDriver = SummaryDriver(
        id: top.driver.id,
        code: top.driver.code,
        fullName: top.driver.fullName,
        color: top.driver.color,
        pickCount: top.pickCount,
        points: top.points,
      );
    }

    return LeagueWeeklySummary(
      bestPrediction: rows.isEmpty ? null : rows.first,
      myStanding: myStanding,
      jokerHitCount: jokerHitCount,
      mostPickedDriver: bestDriver,
      topStandings: rows.take(5).toList(),
      predictionCount: predictionCount,
      predictionItems: predictionItems,
    );
  }
}

class PredictionSummaryItem {
  final String label;
  final String value;
  final bool hit;
  final String status;
  final int points;
  final int maxPoints;

  const PredictionSummaryItem({
    required this.label,
    required this.value,
    required this.hit,
    required this.status,
    required this.points,
    required this.maxPoints,
  });

  factory PredictionSummaryItem.fromJson(Map<String, dynamic> j) =>
      PredictionSummaryItem(
        label: (j['label'] as String?) ?? '',
        value: (j['value'] as String?) ?? '-',
        status:
            (j['status'] as String?) ??
            ((j['hit'] as bool?) == true ? 'correct' : 'wrong'),
        hit: (j['hit'] as bool?) ?? ((j['status'] as String?) != 'wrong'),
        points: ((j['points'] ?? 0) as num).toInt(),
        maxPoints: ((j['max_points'] ?? 0) as num).toInt(),
      );
}

class SummaryDriver {
  final String id;
  final String code;
  final String fullName;
  final String? color;
  final int pickCount;
  final int points;

  SummaryDriver({
    required this.id,
    required this.code,
    required this.fullName,
    required this.color,
    required this.pickCount,
    required this.points,
  });

  factory SummaryDriver.fromJson(Map<String, dynamic> j) => SummaryDriver(
    id: j['id'] as String,
    code: j['code'] as String,
    fullName: j['full_name'] as String,
    color: j['color'] as String?,
    pickCount: ((j['pick_count'] ?? 0) as num).toInt(),
    points: ((j['points'] ?? j['pick_count'] ?? 0) as num).toInt(),
  );
}
