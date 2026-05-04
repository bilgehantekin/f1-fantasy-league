import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';
import 'data/prediction_repository.dart';
export 'domain/prediction_rules.dart';
import 'domain/prediction_rules.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>(
  (_) => PredictionRepository(supabase),
);

final raceProvider = FutureProvider.autoDispose.family<Race, String>((
  ref,
  id,
) async {
  return ref.read(predictionRepositoryProvider).fetchRace(id);
});

final driversProvider = FutureProvider<List<Driver>>((ref) async {
  return ref
      .read(predictionRepositoryProvider)
      .fetchDrivers(seasonId: Env.seasonId);
});

final jokerProvider = FutureProvider.family<JokerQuestion?, String>((
  ref,
  raceId,
) async {
  return ref.read(predictionRepositoryProvider).fetchJoker(raceId);
});

final predictionProvider = FutureProvider.family<Prediction?, PredictionKey>((
  ref,
  key,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || key.leagueId == null) return null;
  return ref
      .read(predictionRepositoryProvider)
      .fetchPrediction(userId: user.id, key: key);
});

Future<void> upsertPrediction(Prediction p, {required String leagueId}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await PredictionRepository(
    supabase,
  ).upsertPrediction(userId: user.id, prediction: p, leagueId: leagueId);
}

final sprintPredictionProvider =
    FutureProvider.family<SprintPrediction?, PredictionKey>((ref, key) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || key.leagueId == null) return null;
      return ref
          .read(predictionRepositoryProvider)
          .fetchSprintPrediction(userId: user.id, key: key);
    });

Future<void> upsertSprintPrediction(
  SprintPrediction p, {
  required String leagueId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await PredictionRepository(
    supabase,
  ).upsertSprintPrediction(userId: user.id, prediction: p, leagueId: leagueId);
}

Future<void> deletePrediction({
  required String raceId,
  required String leagueId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await PredictionRepository(supabase).deletePrediction(
    userId: user.id,
    raceId: raceId,
    leagueId: leagueId,
  );
}

Future<void> deleteSprintPrediction({
  required String raceId,
  required String leagueId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await PredictionRepository(supabase).deleteSprintPrediction(
    userId: user.id,
    raceId: raceId,
    leagueId: leagueId,
  );
}

Future<void> copyPredictionToLeagues({
  Prediction? main,
  SprintPrediction? sprint,
  required Iterable<String> leagueIds,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';

  await PredictionRepository(supabase).copyPredictionToLeagues(
    userId: user.id,
    main: main,
    sprint: sprint,
    leagueIds: leagueIds,
  );
}
