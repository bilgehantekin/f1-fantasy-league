import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'league_controller.dart';

class LeagueDetailScreen extends ConsumerWidget {
  final String leagueId;
  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueProvider(leagueId));
    final standingsAsync = ref.watch(seasonStandingsProvider(leagueId));
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: leagueAsync.when(
          data: (l) => Text(l.name.toUpperCase()),
          loading: () => const Text('...'),
          error: (_, _) => const Text('LIG'),
        ),
      ),
      body: standingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (rows) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(seasonStandingsProvider(leagueId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              leagueAsync.maybeWhen(
                data: (l) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceHi),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DAVET KODU',
                                style: tt.labelSmall?.copyWith(
                                    color: Colors.white60, letterSpacing: 2)),
                            const SizedBox(height: 4),
                            Text(l.inviteCode,
                                style: tt.displayMedium?.copyWith(
                                    color: AppColors.f1Red,
                                    letterSpacing: 4,
                                    fontSize: 28)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: l.inviteCode));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kopyalandı')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    color: AppColors.f1Red,
                  ),
                  const SizedBox(width: 8),
                  Text('SEZON SIRALAMASI', style: tt.labelLarge),
                ],
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                      'Henüz puan yok. İlk yarış sonucundan sonra dolacak.',
                      style: tt.bodyMedium),
                ),
              for (final row in rows) _StandingRow(row: row),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final dynamic row;
  const _StandingRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rank = row.rank as int;
    final username = row.username as String;
    final score = row.score as int;
    final (rankBg, rankFg) = switch (rank) {
      1 => (const Color(0xFFFFD700), Colors.black),
      2 => (const Color(0xFFC0C0C0), Colors.black),
      3 => (const Color(0xFFCD7F32), Colors.black),
      _ => (AppColors.surfaceHi, Colors.white),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$rank',
                style: tt.titleMedium?.copyWith(
                    color: rankFg, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(username,
                  style: tt.titleMedium?.copyWith(letterSpacing: 0))),
          Text('$score',
              style: tt.headlineMedium?.copyWith(color: AppColors.f1Red)),
          const SizedBox(width: 4),
          Text('PTS',
              style:
                  tt.labelSmall?.copyWith(color: Colors.white54, fontSize: 9)),
        ],
      ),
    );
  }
}
