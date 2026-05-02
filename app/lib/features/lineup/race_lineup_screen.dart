import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../shared/country_flags.dart';
import '../../shared/models.dart';
import '../prediction/prediction_controller.dart';

/// Yaklaşan yarışlarda calendar'dan tıklayınca açılan ekran.
/// Tahmin ekranı DEĞİL — sadece o yarışta yarışacak sürücüleri takıma göre listeler.
class RaceLineupScreen extends ConsumerWidget {
  final String raceId;
  final bool sprintMode;
  const RaceLineupScreen({
    super.key,
    required this.raceId,
    this.sprintMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final driversAsync = ref.watch(driversProvider);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: raceAsync.maybeWhen(
          data: (r) => Text(
            sprintMode
                ? '${r.name.toUpperCase()} · SPRINT'
                : r.name.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          orElse: () => Text(
            sprintMode ? 'SPRINT KADROSU' : 'YARIŞ KADROSU',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFF1F1F2E)),
        ),
      ),
      body: raceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (race) => driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (drivers) => ListView(
            padding: EdgeInsets.zero,
            children: [
              _RaceInfoHeader(race: race, sprintMode: sprintMode),
              const SizedBox(height: 16),
              const _SectionTitle(label: 'PİSTE ÇIKACAK SÜRÜCÜLER'),
              _DriversByTeam(drivers: drivers),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaceInfoHeader extends StatelessWidget {
  final Race race;
  final bool sprintMode;
  const _RaceInfoHeader({required this.race, this.sprintMode = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final qAt = sprintMode
        ? race.sprintQualifyingAt
        : race.qualifyingAt;
    final rAt = sprintMode ? race.sprintRaceAt : race.raceAt;
    final qDate = qAt != null
        ? DateFormat('d MMM HH:mm').format(qAt.toLocal())
        : '—';
    final rDate = rAt != null
        ? DateFormat('d MMM HH:mm').format(rAt.toLocal())
        : '—';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: sprintMode ? AppColors.lockOrange : AppColors.lockGreen,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'R${race.round}',
                style: tt.titleMedium?.copyWith(
                  color: AppColors.f1Red,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(flagFor(race.name), style: const TextStyle(fontSize: 16)),
              if (sprintMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lockOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.lockOrange, width: 1),
                  ),
                  child: const Text(
                    'SPRINT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lockOrange,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sprintMode ? '${race.name} · SPRINT' : race.name,
            style: tt.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            race.circuit,
            style: const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaPill(
                label: sprintMode ? 'SPRINT QUALI' : 'SIRALAMA',
                value: qDate,
              ),
              const SizedBox(width: 8),
              _MetaPill(
                label: sprintMode ? 'SPRINT YARIŞ' : 'YARIŞ',
                value: rDate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;
  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.f1Red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriversByTeam extends StatelessWidget {
  final List<Driver> drivers;
  const _DriversByTeam({required this.drivers});

  @override
  Widget build(BuildContext context) {
    // Takıma göre grupla
    final byTeam = <String, List<Driver>>{};
    final teamOrder = <String>[];
    final teamColors = <String, String?>{};
    final teamNames = <String, String>{};
    for (final d in drivers) {
      final key = d.teamCode ?? d.teamId ?? '—';
      if (!byTeam.containsKey(key)) {
        byTeam[key] = [];
        teamOrder.add(key);
        teamColors[key] = d.teamColor;
        teamNames[key] = d.teamName ?? d.teamCode ?? '—';
      }
      byTeam[key]!.add(d);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var t = 0; t < teamOrder.length; t++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              (teamColors[teamOrder[t]] ?? '#6E6E80')
                                  .replaceAll('#', '0xFF'),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        teamNames[teamOrder[t]]!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final d in byTeam[teamOrder[t]]!)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              d.number != null ? '${d.number}' : '—',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0x99FFFFFF),
                              ),
                            ),
                          ),
                          Text(
                            d.code,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d.fullName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (t < teamOrder.length - 1)
                    const Divider(
                      height: 16,
                      color: Color(0xFF15151E),
                      thickness: 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
