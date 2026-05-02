import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../country_flags.dart';
import '../models.dart';

class RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onTap;
  const RaceCard({super.key, required this.race, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM');
    final timeFmt = DateFormat('HH:mm');
    final tt = Theme.of(context).textTheme;
    final (statusLabel, statusColor) = switch (race.status) {
      RaceStatus.upcoming when race.isLocked => (
        'KİLİTLİ',
        AppColors.lockOrange,
      ),
      RaceStatus.upcoming => ('TAHMİN AÇIK', AppColors.lockGreen),
      RaceStatus.locked => ('KİLİTLİ', AppColors.lockOrange),
      RaceStatus.live => ('CANLI', AppColors.liveRed),
      RaceStatus.finished => ('TAMAMLANDI', AppColors.finished),
      RaceStatus.cancelled => ('İPTAL', AppColors.finished),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Round badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.f1Red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'R${race.round}',
                      style: tt.headlineMedium?.copyWith(letterSpacing: -0.5),
                    ),
                    Text(
                      fmt.format(race.raceAt.toLocal()).toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          flagFor(race.name),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            race.name,
                            style: tt.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      race.circuit,
                      style: tt.bodySmall?.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(label: statusLabel, color: statusColor),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          timeFmt.format(race.raceAt.toLocal()),
                          style: tt.labelSmall?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
