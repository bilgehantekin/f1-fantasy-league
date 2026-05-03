import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
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

final adminJokerProvider = FutureProvider.family<JokerQuestion?, String>((
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

final adminRaceAuditProvider = FutureProvider.family<AdminRaceAudit, Race>((
  ref,
  race,
) async {
  final mainRows = await supabase
      .from('race_results')
      .select()
      .eq('race_id', race.id)
      .limit(1);
  final sprintRows = await supabase
      .from('sprint_results')
      .select()
      .eq('race_id', race.id)
      .limit(1);
  final mainClassRows = await supabase
      .from('race_classifications')
      .select('driver_id')
      .eq('race_id', race.id);
  final sprintClassRows = await supabase
      .from('sprint_classifications')
      .select('driver_id')
      .eq('race_id', race.id);

  return AdminRaceAudit(
    mainResult: mainRows.isEmpty ? null : mainRows.first,
    sprintResult: sprintRows.isEmpty ? null : sprintRows.first,
    mainClassificationRows: mainClassRows.length,
    sprintClassificationRows: sprintClassRows.length,
  );
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

Future<void> ingestRaceFromOpenF1(String raceId) async {
  await supabase.functions.invoke('ingest-openf1', body: {'race_id': raceId});
}

class AdminRaceAudit {
  final Map<String, dynamic>? mainResult;
  final Map<String, dynamic>? sprintResult;
  final int mainClassificationRows;
  final int sprintClassificationRows;

  const AdminRaceAudit({
    required this.mainResult,
    required this.sprintResult,
    required this.mainClassificationRows,
    required this.sprintClassificationRows,
  });

  int? get mainDnf => (mainResult?['dnf_count'] as num?)?.toInt();
  int? get sprintDnf => (sprintResult?['dnf_count'] as num?)?.toInt();
}
