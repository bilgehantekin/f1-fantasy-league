import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (row == null) return null;
  return Profile.fromJson(row);
});

Future<void> completeOnboarding({String? username}) async {
  await supabase.rpc('complete_onboarding', params: {'p_username': username});
}

final allBadgesProvider = FutureProvider<List<AppBadge>>((ref) async {
  final rows = await supabase.from('badges').select().order('rarity');
  return rows.map((e) => AppBadge.fromJson(e)).toList();
});

final myBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase
      .from('user_badges')
      .select('*, badge:badges(*)')
      .eq('user_id', user.id)
      .order('awarded_at', ascending: false);
  return rows.map((e) => UserBadge.fromJson(e)).toList();
});

class ProfileStats {
  final int totalScore;
  final int badgeCount;
  final int racesPredicted;
  final int bestScore;
  final double averageScore;
  ProfileStats({
    required this.totalScore,
    required this.badgeCount,
    required this.racesPredicted,
    required this.bestScore,
    required this.averageScore,
  });
}

class CategoryAccuracy {
  final String category;
  final int correct;
  final int total;
  CategoryAccuracy({
    required this.category,
    required this.correct,
    required this.total,
  });
  double get rate => total == 0 ? 0 : correct / total;
}

class TrendPoint {
  final int round;
  final String raceName;
  final int score;
  TrendPoint({
    required this.round,
    required this.raceName,
    required this.score,
  });
}

class DriverAccuracy {
  final String code;
  final String fullName;
  final String? color;
  final int predicted;
  final int correct;
  DriverAccuracy({
    required this.code,
    required this.fullName,
    required this.color,
    required this.predicted,
    required this.correct,
  });
  double get rate => predicted == 0 ? 0 : correct / predicted;
}

final categoryAccuracyProvider = FutureProvider<List<CategoryAccuracy>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_category_accuracy',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => CategoryAccuracy(
          category: e['category'] as String,
          correct: ((e['correct'] ?? 0) as num).toInt(),
          total: ((e['total'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final seasonTrendProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_season_trend',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => TrendPoint(
          round: (e['round'] as num).toInt(),
          raceName: e['race_name'] as String,
          score: ((e['score'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final driverAccuracyProvider = FutureProvider<List<DriverAccuracy>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await supabase.rpc(
    'user_driver_accuracy',
    params: {'p_user_id': user.id, 'p_season_id': Env.seasonId},
  );
  return (rows as List)
      .map(
        (e) => DriverAccuracy(
          code: e['code'] as String,
          fullName: e['full_name'] as String,
          color: e['color'] as String?,
          predicted: ((e['predicted'] ?? 0) as num).toInt(),
          correct: ((e['correct'] ?? 0) as num).toInt(),
        ),
      )
      .toList();
});

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return ProfileStats(
      totalScore: 0,
      badgeCount: 0,
      racesPredicted: 0,
      bestScore: 0,
      averageScore: 0,
    );
  }
  final preds = await supabase
      .from('predictions')
      .select('race_id, score')
      .eq('user_id', user.id);
  final bestByRace = <String, int>{};
  int best = 0;
  for (final p in preds) {
    if (p['score'] != null) {
      final score = (p['score'] as num).toInt();
      final raceId = p['race_id'] as String;
      final prev = bestByRace[raceId];
      if (prev == null || score > prev) {
        bestByRace[raceId] = score;
      }
      if (score > best) best = score;
    }
  }
  final total = bestByRace.values.fold<int>(0, (sum, score) => sum + score);
  final scored = bestByRace.length;
  final badges = await supabase
      .from('user_badges')
      .select('id')
      .eq('user_id', user.id);
  return ProfileStats(
    totalScore: total,
    badgeCount: badges.length,
    racesPredicted: scored,
    bestScore: best,
    averageScore: scored == 0 ? 0 : total / scored,
  );
});
