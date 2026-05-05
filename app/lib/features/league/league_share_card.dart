import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/models.dart';
import 'share_card_atoms.dart';

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
    final others = standings.skip(3).take(3).toList();
    final memberText = league.memberCount == null
        ? '${standings.length} oyuncu'
        : '${league.memberCount} oyuncu';

    return ShareStoryFrame(
      width: 1080,
      height: 1920,
      padding: const EdgeInsets.fromLTRB(80, 120, 80, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShareGridCallLogo(fontSize: 40, bulbSize: 14),
              const Spacer(),
              ShareSeasonPill(label: 'SEZON ${league.seasonId}'),
            ],
          ),
          const SizedBox(height: 80),
          Text(
            'LİGİN ADI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            league.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.w900,
              height: 0.92,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 90),
          if (topRows.isNotEmpty)
            _Podium(topRows: topRows)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: const Text(
                'İlk yarış sonucundan sonra sıralama burada görünecek.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 56),
            for (final row in others)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ShareStandingLine(row: row),
              ),
          ],
          const Spacer(),
          ShareInviteBox(code: league.inviteCode),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                '$memberText · ${standings.length} sıralama',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              Text(
                inviteLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<StandingRow> topRows;

  const _Podium({required this.topRows});

  @override
  Widget build(BuildContext context) {
    final first = topRows[0];
    final second = topRows.length > 1 ? topRows[1] : null;
    final third = topRows.length > 2 ? topRows[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox(height: 300)
              : _PodiumBar(
                  row: second,
                  place: 2,
                  height: 280,
                  accent: shareSilver,
                ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _PodiumBar(
            row: first,
            place: 1,
            height: 360,
            accent: shareGold,
            crown: true,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: third == null
              ? const SizedBox(height: 240)
              : _PodiumBar(
                  row: third,
                  place: 3,
                  height: 220,
                  accent: shareBronze,
                ),
        ),
      ],
    );
  }
}

class _PodiumBar extends StatelessWidget {
  final StandingRow row;
  final int place;
  final double height;
  final Color accent;
  final bool crown;

  const _PodiumBar({
    required this.row,
    required this.place,
    required this.height,
    required this.accent,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (crown) ...[
          const Icon(Icons.workspace_premium, size: 56, color: shareGold),
          const SizedBox(height: 8),
        ],
        Text(
          row.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '${row.score}',
            children: [
              TextSpan(
                text: ' PTS',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.f1Red,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, accent.withValues(alpha: 0.54)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 60),
            ],
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            '$place',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.55),
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
