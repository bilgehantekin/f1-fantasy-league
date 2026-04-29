import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final racesProvider = FutureProvider<List<Race>>((ref) async {
  final rows = await supabase
      .from('races')
      .select()
      .eq('season_id', Env.seasonId)
      .order('round');
  return rows.map((e) => Race.fromJson(e)).toList();
});
