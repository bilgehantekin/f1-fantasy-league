import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final raceProvider = FutureProvider.autoDispose.family<Race, String>((
  ref,
  id,
) async {
  final row = await supabase.from('races').select().eq('id', id).single();
  return Race.fromJson(row);
});

final driversProvider = FutureProvider<List<Driver>>((ref) async {
  final rows = await supabase
      .from('drivers')
      .select('*, team:teams(code, name, color)')
      .eq('season_id', Env.seasonId)
      .order('full_name');
  return rows.map((e) => Driver.fromJson(e)).toList();
});

final jokerProvider = FutureProvider.family<JokerQuestion?, String>((
  ref,
  raceId,
) async {
  final rows = await supabase
      .from('joker_questions')
      .select()
      .eq('race_id', raceId)
      .limit(1);
  if (rows.isEmpty) return null;
  return JokerQuestion.fromJson(rows.first);
});

class PredictionKey {
  final String raceId;
  final String? leagueId;

  const PredictionKey({required this.raceId, this.leagueId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionKey &&
          raceId == other.raceId &&
          leagueId == other.leagueId;

  @override
  int get hashCode => Object.hash(raceId, leagueId);
}

final predictionProvider = FutureProvider.family<Prediction?, PredictionKey>((
  ref,
  key,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || key.leagueId == null) return null;
  final rows = await supabase
      .from('predictions')
      .select()
      .eq('user_id', user.id)
      .eq('race_id', key.raceId)
      .eq('league_id', key.leagueId!)
      .limit(1);
  if (rows.isEmpty) return null;
  return Prediction.fromJson(rows.first);
});

Future<void> upsertPrediction(Prediction p, {required String leagueId}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await supabase
      .from('predictions')
      .upsert(
        p.toUpsertJson(user.id, leagueId: leagueId),
        onConflict: 'user_id,race_id,league_id',
      );
}

final sprintPredictionProvider =
    FutureProvider.family<SprintPrediction?, PredictionKey>((ref, key) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || key.leagueId == null) return null;
      final rows = await supabase
          .from('sprint_predictions')
          .select()
          .eq('user_id', user.id)
          .eq('race_id', key.raceId)
          .eq('league_id', key.leagueId!)
          .limit(1);
      if (rows.isEmpty) return null;
      return SprintPrediction.fromJson(rows.first);
    });

Future<void> upsertSprintPrediction(
  SprintPrediction p, {
  required String leagueId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await supabase
      .from('sprint_predictions')
      .upsert(
        p.toUpsertJson(user.id, leagueId: leagueId),
        onConflict: 'user_id,race_id,league_id',
      );
}

Future<void> copyPredictionToLeagues({
  Prediction? main,
  SprintPrediction? sprint,
  required Iterable<String> leagueIds,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';

  final targetIds = leagueIds.toSet();
  if (targetIds.isEmpty) return;

  if (main != null) {
    await supabase.from('predictions').upsert([
      for (final leagueId in targetIds)
        main.toUpsertJson(user.id, leagueId: leagueId),
    ], onConflict: 'user_id,race_id,league_id');
  }

  if (sprint != null) {
    await supabase.from('sprint_predictions').upsert([
      for (final leagueId in targetIds)
        sprint.toUpsertJson(user.id, leagueId: leagueId),
    ], onConflict: 'user_id,race_id,league_id');
  }
}
