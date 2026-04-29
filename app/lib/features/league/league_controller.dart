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
  final rows = await supabase.rpc('league_season_standings', params: {
    'p_league_id': leagueId,
    'p_season_id': Env.seasonId,
  });
  return (rows as List)
      .map((e) => StandingRow.season(e as Map<String, dynamic>))
      .toList();
});

Future<String> createLeague(String name) async {
  final res = await supabase.rpc('create_league', params: {
    'p_name': name,
    'p_season_id': Env.seasonId,
  });
  return res as String;
}

Future<String> joinLeagueByCode(String code) async {
  final res = await supabase.rpc('join_league_by_code', params: {
    'p_code': code.toUpperCase(),
  });
  return res as String;
}
