import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/models.dart';
import 'league_controller.dart';

/// Hikaye/feed paylaşımına uygun 1080x1920 dikey kart.
class WeeklySummaryShareCard extends StatelessWidget {
  final League league;
  final Race race;
  final LeagueWeeklySummary summary;
  final bool sprintMode;

  const WeeklySummaryShareCard({
    super.key,
    required this.league,
    required this.race,
    required this.summary,
    required this.sprintMode,
  });

  @override
  Widget build(BuildContext context) {
    final best = summary.bestPrediction;
    final picked = summary.mostPickedDriver;
    final top = summary.topStandings.take(3).toList();
    final modeLabel = sprintMode ? 'SPRINT' : 'YARIŞ';

    return Material(
      color: AppColors.carbon,
      child: Container(
        width: 1080,
        height: 1920,
        padding: const EdgeInsets.fromLTRB(64, 80, 64, 80),
        decoration: const BoxDecoration(color: AppColors.carbon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 16, height: 64, color: AppColors.f1Red),
                const SizedBox(width: 24),
                const Text(
                  'GRIDCALL',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    modeLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            Text(
              '${league.name.toUpperCase()} · R${race.round}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xCCFFFFFF),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              race.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 56),
            const Text(
              'HAFTANIN KAZANANI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(20),
                border: const Border(
                  left: BorderSide(color: AppColors.f1Red, width: 8),
                ),
              ),
              child: best == null
                  ? const Text(
                      'Henüz skor hesaplanmadı.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xB3FFFFFF),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            best.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '${best.score}',
                          style: const TextStyle(
                            fontSize: 88,
                            fontWeight: FontWeight.w900,
                            color: AppColors.f1Red,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Text(
                            'PTS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 48),
            const Text(
              'İLK 3',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 16),
            if (top.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Bu yarış için skorlanmış tahmin yok.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              )
            else
              for (final row in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShareStandingRow(row: row),
                ),
            const Spacer(),
            if (picked != null) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 56,
                    decoration: BoxDecoration(
                      color: picked.color == null
                          ? AppColors.f1Red
                          : Color(
                              int.parse(picked.color!.replaceAll('#', '0xFF')),
                            ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EN ÇOK PUAN KAZANDIRAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${picked.code} · ${picked.fullName}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KATIL · DAVET KODU',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  Text(
                    league.inviteCode,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      color: AppColors.f1Red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareStandingRow extends StatelessWidget {
  final StandingRow row;

  const _ShareStandingRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (row.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.surfaceHi,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${row.rank}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 22),
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
            '${row.score}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.f1Red,
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'PTS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0x99FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
