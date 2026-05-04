import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models.dart';
import '../domain/prediction_rules.dart';

class PredictionRepository {
  final SupabaseClient _client;

  const PredictionRepository(this._client);

  Future<Race> fetchRace(String id) async {
    final row = await _client.from('races').select().eq('id', id).single();
    return Race.fromJson(row);
  }

  Future<List<Driver>> fetchDrivers({required int seasonId}) async {
    final rows = await _client
        .from('drivers')
        .select('*, team:teams(code, name, color)')
        .eq('season_id', seasonId)
        .order('full_name');
    return rows.map((e) => Driver.fromJson(e)).toList();
  }

  Future<JokerQuestion?> fetchJoker(String raceId) async {
    final rows = await _client
        .from('joker_questions')
        .select()
        .eq('race_id', raceId)
        .limit(1);
    if (rows.isEmpty) return null;
    return JokerQuestion.fromJson(rows.first);
  }

  Future<Prediction?> fetchPrediction({
    required String userId,
    required PredictionKey key,
  }) async {
    if (key.leagueId == null) return null;
    final rows = await _client
        .from('predictions')
        .select()
        .eq('user_id', userId)
        .eq('race_id', key.raceId)
        .eq('league_id', key.leagueId!)
        .limit(1);
    if (rows.isEmpty) return null;
    return Prediction.fromJson(rows.first);
  }

  Future<void> upsertPrediction({
    required String userId,
    required Prediction prediction,
    required String leagueId,
  }) async {
    await _client
        .from('predictions')
        .upsert(
          prediction.toUpsertJson(userId, leagueId: leagueId),
          onConflict: 'user_id,race_id,league_id',
        );
  }

  Future<SprintPrediction?> fetchSprintPrediction({
    required String userId,
    required PredictionKey key,
  }) async {
    if (key.leagueId == null) return null;
    final rows = await _client
        .from('sprint_predictions')
        .select()
        .eq('user_id', userId)
        .eq('race_id', key.raceId)
        .eq('league_id', key.leagueId!)
        .limit(1);
    if (rows.isEmpty) return null;
    return SprintPrediction.fromJson(rows.first);
  }

  Future<void> upsertSprintPrediction({
    required String userId,
    required SprintPrediction prediction,
    required String leagueId,
  }) async {
    await _client
        .from('sprint_predictions')
        .upsert(
          prediction.toUpsertJson(userId, leagueId: leagueId),
          onConflict: 'user_id,race_id,league_id',
        );
  }

  Future<void> deletePrediction({
    required String userId,
    required String raceId,
    required String leagueId,
  }) async {
    await _client
        .from('predictions')
        .delete()
        .eq('user_id', userId)
        .eq('race_id', raceId)
        .eq('league_id', leagueId);
  }

  Future<void> deleteSprintPrediction({
    required String userId,
    required String raceId,
    required String leagueId,
  }) async {
    await _client
        .from('sprint_predictions')
        .delete()
        .eq('user_id', userId)
        .eq('race_id', raceId)
        .eq('league_id', leagueId);
  }

  Future<void> copyPredictionToLeagues({
    required String userId,
    Prediction? main,
    SprintPrediction? sprint,
    required Iterable<String> leagueIds,
  }) async {
    final targetIds = normalizeTargetLeagueIds(leagueIds);
    if (targetIds.isEmpty) return;

    if (main != null) {
      await _client.from('predictions').upsert([
        for (final leagueId in targetIds)
          main.toUpsertJson(userId, leagueId: leagueId),
      ], onConflict: 'user_id,race_id,league_id');
    }

    if (sprint != null) {
      await _client.from('sprint_predictions').upsert([
        for (final leagueId in targetIds)
          sprint.toUpsertJson(userId, leagueId: leagueId),
      ], onConflict: 'user_id,race_id,league_id');
    }
  }
}
