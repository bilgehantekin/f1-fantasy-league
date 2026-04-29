import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  if (supabase.auth.currentUser == null) return false;
  final res = await supabase.rpc('is_current_user_admin');
  return (res as bool?) ?? false;
});

final adminRacesProvider = FutureProvider<List<Race>>((ref) async {
  final rows = await supabase
      .from('races')
      .select()
      .eq('season_id', Env.seasonId)
      .order('round');
  return rows.map((e) => Race.fromJson(e)).toList();
});

final adminJokerProvider =
    FutureProvider.family<JokerQuestion?, String>((ref, raceId) async {
  final rows = await supabase
      .from('joker_questions')
      .select()
      .eq('race_id', raceId)
      .limit(1);
  if (rows.isEmpty) return null;
  return JokerQuestion.fromJson(rows.first);
});

Future<void> upsertJoker({
  required String raceId,
  required String text,
  required List<String> options,
  String? correct,
  int points = 12,
}) async {
  final existing = await supabase
      .from('joker_questions')
      .select('id')
      .eq('race_id', raceId)
      .maybeSingle();

  final payload = {
    'race_id': raceId,
    'text': text,
    'options': options,
    'correct_option': correct,
    'points': points,
  };
  if (existing == null) {
    await supabase.from('joker_questions').insert(payload);
  } else {
    await supabase
        .from('joker_questions')
        .update(payload)
        .eq('id', existing['id'] as String);
  }
}
