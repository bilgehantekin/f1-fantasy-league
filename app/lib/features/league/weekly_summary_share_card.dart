import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import 'league_controller.dart';
import 'share_card_atoms.dart';

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

    return ShareStoryFrame(
      width: 1080,
      height: 1920,
      padding: const EdgeInsets.fromLTRB(80, 120, 80, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShareGridCallLogo(fontSize: 32, bulbSize: 11),
              const Spacer(),
              Text(
                'R${race.round}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 14),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 60),
          Text(
            '${league.name} · Haftalık Özet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            race.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 78,
              fontWeight: FontWeight.w900,
              height: 0.95,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
          const SizedBox(height: 80),
          _WinnerScoreBlock(best: best),
          const SizedBox(height: 54),
          Text(
            'LİG ÖZETİ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryStatTile(
                  label: sprintMode ? 'TAHMİN' : 'JOKER',
                  value: sprintMode
                      ? '${summary.predictionCount}'
                      : '${summary.jokerHitCount}',
                  subvalue: sprintMode ? 'kayıtlı tahmin' : 'bilen kişi',
                  color: sprintMode
                      ? AppColors.lockOrange
                      : AppColors.lockGreen,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _SummaryStatTile(
                  label: 'HAFTANIN SÜRÜCÜSÜ',
                  value: picked?.code ?? '-',
                  subvalue: picked == null
                      ? 'tahmin yok'
                      : '${picked.points} puan · ${picked.pickCount} seçim',
                  color: _colorFromHex(picked?.color) ?? AppColors.f1Red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Text(
            'İLK 3',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 18),
          if (top.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Text(
                'Bu yarış için skorlanmış tahmin yok.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0x99FFFFFF),
                ),
              ),
            )
          else
            for (final row in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ShareStandingLine(row: row, compact: true),
              ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Expanded(child: _BottomWinner(best: best)),
                const SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KOD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      league.inviteCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.f1Red,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerScoreBlock extends StatelessWidget {
  final StandingRow? best;

  const _WinnerScoreBlock({required this.best});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(54, 46, 54, 46),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceHi],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: best == null
          ? const Text(
              'Henüz skor hesaplanmadı.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xB3FFFFFF),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HAFTANIN KAZANANI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        best!.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 34),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${best!.score}',
                      style: const TextStyle(
                        fontSize: 124,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        color: AppColors.f1Red,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;
  final Color color;

  const _SummaryStatTile({
    required this.label,
    required this.value,
    required this.subvalue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomWinner extends StatelessWidget {
  final StandingRow? best;

  const _BottomWinner({required this.best});

  @override
  Widget build(BuildContext context) {
    if (best == null) {
      return const Text(
        'Skorlar hesaplanınca haftanın birincisi burada olacak.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xCCFFFFFF),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HAFTANIN BİRİNCİSİ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${best!.username} · ${best!.score}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

Color? _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? null : Color(value);
}
