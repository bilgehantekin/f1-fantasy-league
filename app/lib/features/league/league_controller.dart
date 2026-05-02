import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final myLeaguesProvider = FutureProvider<List<League>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final rows = await supabase
      .from('leagues')
      .select('*, league_memberships!inner(user_id)')
      .eq('league_memberships.user_id', user.id);
  return rows.map((e) => League.fromJson(e)).toList();
});

final leagueProvider = FutureProvider.family<League, String>((ref, id) async {
  final row = await supabase.from('leagues').select().eq('id', id).single();
  return League.fromJson(row);
});

final seasonStandingsProvider =
    FutureProvider.family<List<StandingRow>, String>((ref, leagueId) async {
      final rows = await supabase.rpc(
        'league_season_standings',
        params: {'p_league_id': leagueId, 'p_season_id': Env.seasonId},
      );
      return (rows as List)
          .map((e) => StandingRow.season(e as Map<String, dynamic>))
          .toList();
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

final weeklySummaryProvider =
    FutureProvider.family<LeagueWeeklySummary, WeeklySummaryKey>((
      ref,
      key,
    ) async {
      final res = await supabase.rpc(
        'league_weekly_summary',
        params: {'p_league_id': key.leagueId, 'p_race_id': key.raceId},
      );
      return LeagueWeeklySummary.fromJson(res as Map<String, dynamic>);
    });

final leaguePredictionStatusProvider =
    FutureProvider.family<LeaguePredictionStatus, String>((
      ref,
      leagueId,
    ) async {
      final user = supabase.auth.currentUser;
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
    params: {'p_code': code.toUpperCase()},
  );
  return res as String;
}

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

class LeagueMember {
  final String userId;
  final String username;
  final String role;
  final DateTime joinedAt;

  LeagueMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
  });

  factory LeagueMember.fromJson(Map<String, dynamic> j) => LeagueMember(
    userId: j['user_id'] as String,
    username: j['username'] as String,
    role: j['role'] as String,
    joinedAt: DateTime.parse(j['joined_at'] as String),
  );
}

class WeeklySummaryKey {
  final String leagueId;
  final String raceId;

  const WeeklySummaryKey({required this.leagueId, required this.raceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklySummaryKey &&
          leagueId == other.leagueId &&
          raceId == other.raceId;

  @override
  int get hashCode => Object.hash(leagueId, raceId);
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
  final int jokerHitCount;
  final SummaryDriver? mostPickedDriver;
  final List<StandingRow> topStandings;
  final int predictionCount;

  LeagueWeeklySummary({
    required this.bestPrediction,
    required this.jokerHitCount,
    required this.mostPickedDriver,
    required this.topStandings,
    required this.predictionCount,
  });

  factory LeagueWeeklySummary.fromJson(Map<String, dynamic> j) {
    final best = j['best_prediction'] as Map<String, dynamic>? ?? {};
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
    return LeagueWeeklySummary(
      bestPrediction: best['user_id'] == null
          ? null
          : StandingRow(
              userId: best['user_id'] as String,
              username: best['username'] as String,
              score: ((best['score'] ?? 0) as num).toInt(),
              rank: 1,
            ),
      jokerHitCount: ((j['joker_hit_count'] ?? 0) as num).toInt(),
      mostPickedDriver: mostPicked['id'] == null
          ? null
          : SummaryDriver.fromJson(mostPicked),
      topStandings: rows,
      predictionCount: ((j['prediction_count'] ?? 0) as num).toInt(),
    );
  }
}

class SummaryDriver {
  final String id;
  final String code;
  final String fullName;
  final String? color;
  final int pickCount;

  SummaryDriver({
    required this.id,
    required this.code,
    required this.fullName,
    required this.color,
    required this.pickCount,
  });

  factory SummaryDriver.fromJson(Map<String, dynamic> j) => SummaryDriver(
    id: j['id'] as String,
    code: j['code'] as String,
    fullName: j['full_name'] as String,
    color: j['color'] as String?,
    pickCount: ((j['pick_count'] ?? 0) as num).toInt(),
  );
}
