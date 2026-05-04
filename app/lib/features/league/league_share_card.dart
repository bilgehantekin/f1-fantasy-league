import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/models.dart';

class LeagueShareCard extends StatelessWidget {
  final League league;
  final List<StandingRow> standings;
  final String inviteLink;

  const LeagueShareCard({
    super.key,
    required this.league,
    required this.standings,
    required this.inviteLink,
  });

  @override
  Widget build(BuildContext context) {
    final topRows = standings.take(3).toList();

    return Material(
      color: AppColors.carbon,
      child: Container(
        width: 1080,
        height: 1080,
        padding: const EdgeInsets.all(56),
        decoration: const BoxDecoration(color: AppColors.carbon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 18, height: 72, color: AppColors.f1Red),
                const SizedBox(width: 28),
                const Text(
                  'GRIDCALL',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              league.name.toUpperCase(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 78,
                fontWeight: FontWeight.w900,
                height: 0.94,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'F1 tahmin ligime katil',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xCCFFFFFF),
              ),
            ),
            const SizedBox(height: 42),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHi, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DAVET KODU',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(width: 26),
                  Text(
                    league.inviteCode,
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 7,
                      color: AppColors.f1Red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            if (topRows.isNotEmpty) ...[
              const Text(
                'ILK 3',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Color(0x99FFFFFF),
                ),
              ),
              const SizedBox(height: 18),
              for (final row in topRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StandingShareRow(row: row),
                ),
            ] else
              const Text(
                'Ilk yaris sonucundan sonra siralama burada gorunecek.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0x99FFFFFF),
                ),
              ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                inviteLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingShareRow extends StatelessWidget {
  final StandingRow row;

  const _StandingShareRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (row.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.surfaceHi,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${row.rank}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              row.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '${row.score} PTS',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.f1Red,
            ),
          ),
        ],
      ),
    );
  }
}
