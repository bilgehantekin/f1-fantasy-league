import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final raceProvider = FutureProvider.family<Race, String>((ref, id) async {
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

final jokerProvider =
    FutureProvider.family<JokerQuestion?, String>((ref, raceId) async {
  final rows = await supabase
      .from('joker_questions')
      .select()
      .eq('race_id', raceId)
      .limit(1);
  if (rows.isEmpty) return null;
  return JokerQuestion.fromJson(rows.first);
});

final predictionProvider =
    FutureProvider.family<Prediction?, String>((ref, raceId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final rows = await supabase
      .from('predictions')
      .select()
      .eq('user_id', user.id)
      .eq('race_id', raceId)
      .limit(1);
  if (rows.isEmpty) return null;
  return Prediction.fromJson(rows.first);
});

Future<void> upsertPrediction(Prediction p) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw 'Auth required';
  await supabase
      .from('predictions')
      .upsert(p.toUpsertJson(user.id), onConflict: 'user_id,race_id');
}
