import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/env.dart';
import '../../core/theme.dart';
import '../country_flags.dart';
import '../models.dart';
import 'live_pulse_dot.dart';

enum RaceCardKind { main, sprint }

typedef RaceCardEntry = ({Race race, RaceCardKind kind});

List<Race> buildPreviousAndNextRaces(List<Race> races, {DateTime? now}) {
  if (races.isEmpty) return const [];
  final t = now ?? DateTime.now();
  final sorted = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
  Race? previous;
  Race? next;
  for (final race in sorted) {
    if (!race.raceAt.isAfter(t)) {
      previous = race;
    } else {
      next ??= race;
    }
  }
  final selected = <Race>[];
  if (previous != null) selected.add(previous);
  if (next != null && next.id != previous?.id) selected.add(next);
  return selected;
}

Future<RaceCardKind?> showRaceKindPicker(
  BuildContext context, {
  required Race race,
  required String title,
  bool mainSaved = false,
  bool sprintSaved = false,
}) {
  if (!race.hasSprint) {
    return Future.value(RaceCardKind.main);
  }

  return showModalBottomSheet<RaceCardKind>(
    context: context,
    backgroundColor: AppColors.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                race.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0x99FFFFFF),
                ),
              ),
              const SizedBox(height: 16),
              _RaceKindOption(
                label: 'Sprint yarışı',
                subtitle: _eventSubtitle(
                  race.sprintRaceAt,
                  effectiveRaceCardStatus((
                    race: race,
                    kind: RaceCardKind.sprint,
                  )),
                ),
                icon: Icons.bolt_outlined,
                saved: sprintSaved,
                onTap: () => Navigator.of(context).pop(RaceCardKind.sprint),
              ),
              const SizedBox(height: 10),
              _RaceKindOption(
                label: 'Ana yarış',
                subtitle: _eventSubtitle(
                  race.raceAt,
                  effectiveRaceCardStatus((
                    race: race,
                    kind: RaceCardKind.main,
                  )),
                ),
                icon: Icons.flag_outlined,
                saved: mainSaved,
                onTap: () => Navigator.of(context).pop(RaceCardKind.main),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _eventSubtitle(DateTime? at, RaceStatus status) {
  final statusLabel = switch (status) {
    RaceStatus.upcoming => 'Tahmine açık',
    RaceStatus.locked => 'Kilitli',
    RaceStatus.live => 'Canlı',
    RaceStatus.finished => 'Tamamlandı',
    RaceStatus.cancelled => 'İptal',
  };
  if (at == null) return statusLabel;
  final date = DateFormat('d MMM HH:mm', 'tr_TR').format(at.toLocal());
  return '$date · $statusLabel';
}

class _RaceKindOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool saved;
  final VoidCallback onTap;

  const _RaceKindOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A26),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF15151E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.f1Red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (saved) ...[
                          const SizedBox(width: 8),
                          const _PredictionBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir Race listesini sprint kartlarını da üreterek sıralar.
///
/// `pinFeaturedRace = false` (ana ekran): tüm kartlar kronolojik (eski → yeni).
///
/// `pinFeaturedRace = true` (lig detayı): "featured race weekend" en üstte
/// kalır (sprint + ana yarış, sprint daima ana yarıştan önce). Featured =
/// ana yarış bitiminden 24 saat geçmemiş ilk yarış. Bu sayede:
///   - Yarış haftası boyunca (sprint bitse bile) iki kart da üstte kalır.
///   - Ana yarış bitiminden 24 saat sonra featured otomatik olarak bir
///     sonraki yarışa kayar; eski yarış kronolojik sırasına düşer.
///   - Bu hafta yarış yoksa en yakın gelecek yarış featured olur.
List<RaceCardEntry> buildOrderedRaceCards(
  List<Race> races, {
  DateTime? now,
  bool pinFeaturedRace = false,
  Duration featuredCooldown = const Duration(hours: 24),
}) {
  final t = now ?? DateTime.now();
  final entries = <RaceCardEntry>[];
  for (final r in races) {
    if (r.hasSprint) entries.add((race: r, kind: RaceCardKind.sprint));
    entries.add((race: r, kind: RaceCardKind.main));
  }

  DateTime keyDate(RaceCardEntry e) => e.kind == RaceCardKind.sprint
      ? (e.race.sprintRaceAt ?? e.race.sprintQualifyingAt ?? e.race.raceAt)
      : e.race.raceAt;

  entries.sort((a, b) => keyDate(a).compareTo(keyDate(b)));

  if (!pinFeaturedRace) return entries;

  final sortedRaces = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
  Race? featured;
  for (final r in sortedRaces) {
    if (r.raceAt.add(featuredCooldown).isAfter(t)) {
      featured = r;
      break;
    }
  }
  if (featured == null) return entries;

  final featuredEntries = <RaceCardEntry>[];
  final rest = <RaceCardEntry>[];
  for (final e in entries) {
    if (e.race.id == featured.id) {
      featuredEntries.add(e);
    } else {
      rest.add(e);
    }
  }
  return [...featuredEntries, ...rest];
}

RaceStatus effectiveRaceCardStatus(RaceCardEntry entry, {DateTime? now}) {
  final rawStatus = entry.kind == RaceCardKind.sprint
      ? entry.race.sprintStatus
      : entry.race.status;
  if (rawStatus != RaceStatus.upcoming) return rawStatus;

  final lockAt = entry.kind == RaceCardKind.sprint
      ? entry.race.sprintLockAt
      : entry.race.lockAt;
  if (lockAt == null) return RaceStatus.locked;
  return (now ?? DateTime.now()).isAfter(lockAt)
      ? RaceStatus.locked
      : RaceStatus.upcoming;
}

class RaceCardNew extends StatelessWidget {
  final Race race;
  final VoidCallback onTap;
  final RaceCardKind kind;
  final bool? predictionSaved;
  final String? actionLabel;
  final IconData? actionIcon;

  /// Lig bağlamında mı gösteriliyor? Calendar (ana ekran) için false:
  /// biten yarışlarda kullanıcının skor/sıralamasını gizler, canlı yarışlarda
  /// ilerleme bilgisini göstermez.
  final bool showLeagueContext;

  const RaceCardNew({
    super.key,
    required this.race,
    required this.onTap,
    this.predictionSaved,
    this.actionLabel,
    this.actionIcon,
    this.showLeagueContext = true,
    this.kind = RaceCardKind.main,
  });

  bool get _isSprint => kind == RaceCardKind.sprint;

  RaceStatus get _status => effectiveRaceCardStatus((race: race, kind: kind));

  DateTime? get _qualifyingAt =>
      _isSprint ? race.sprintQualifyingAt : race.qualifyingAt;

  DateTime? get _raceAt => _isSprint ? race.sprintRaceAt : race.raceAt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final status = _status;

    final (
      bgColor,
      borderColor,
      accentColor,
      statusIcon,
      statusLabel,
    ) = switch (status) {
      RaceStatus.upcoming => (
        AppColors.surfaceLow,
        AppColors.lockGreen,
        AppColors.lockGreen,
        Icons.flag_outlined,
        'TAHMİNE AÇIK',
      ),
      RaceStatus.locked => (
        AppColors.surfaceLow,
        AppColors.lockOrange,
        AppColors.lockOrange,
        Icons.lock_outline,
        'KİLİTLİ',
      ),
      RaceStatus.live => (
        AppColors.surfaceLow,
        AppColors.liveRed,
        AppColors.liveRed,
        Icons.circle,
        'LIVE',
      ),
      RaceStatus.finished => (
        AppColors.surface,
        AppColors.finished,
        AppColors.finished,
        Icons.check_circle_outline,
        'BİTTİ',
      ),
      RaceStatus.cancelled => (
        AppColors.surface,
        AppColors.finished,
        AppColors.finished,
        Icons.block,
        'İPTAL',
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                Row(
                  children: [
                    if (status == RaceStatus.live)
                      const LivePulseDot(size: 14)
                    else
                      Icon(statusIcon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: tt.labelSmall?.copyWith(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showLeagueContext && predictionSaved == true) ...[
                      const Spacer(),
                      const _PredictionBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Race info
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
                    Text(
                      flagFor(race.name),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isSprint ? '${race.name} · Sprint' : race.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  race.circuit,
                  style: tt.bodyMedium?.copyWith(
                    color: const Color(0x99FFFFFF), // white/60
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                // Status-specific content
                if (status == RaceStatus.upcoming ||
                    status == RaceStatus.locked)
                  _buildUpcomingContent(context)
                else ...[
                  if (status == RaceStatus.live) _buildLiveContent(context),
                  if (status == RaceStatus.finished && showLeagueContext)
                    _buildFinishedContent(context),
                  _buildScheduleRow(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleRow(context),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          _CardAction(label: actionLabel!, icon: actionIcon),
        ],
      ],
    );
  }

  Widget _buildScheduleRow(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final qAt = _qualifyingAt;
    final rAt = _raceAt;
    if (qAt == null || rAt == null) {
      return const SizedBox.shrink();
    }
    final qDate = DateFormat('d MMM', 'tr_TR').format(qAt.toLocal());
    final qTime = DateFormat('HH:mm', 'tr_TR').format(qAt.toLocal());
    final rDate = DateFormat('d MMM', 'tr_TR').format(rAt.toLocal());
    final rTime = DateFormat('HH:mm', 'tr_TR').format(rAt.toLocal());

    return Container(
      padding: const EdgeInsets.only(top: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F1F2E), width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'Sıralama: ',
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          Text(
            '$qDate $qTime',
            style: tt.bodySmall?.copyWith(
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Yarış: ',
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
          Text(
            '$rDate $rTime',
            style: tt.bodySmall?.copyWith(
              color: const Color(0xB3FFFFFF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveContent(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (!Env.enableDemoContent) {
      return Text(
        _isSprint ? 'Sprint canlı — aç' : 'Canlı ekranı aç',
        style: tt.bodyMedium?.copyWith(
          color: const Color(0x99FFFFFF),
          fontSize: 14,
        ),
      );
    }

    const currentLap = 43;
    const totalLaps = 50;
    const progress = 86.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LAP $currentLap/$totalLaps',
              style: tt.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${progress.toInt()}%',
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: const Color(0xFF15151E),
              valueColor: const AlwaysStoppedAnimation(AppColors.liveRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedContent(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (!Env.enableDemoContent) {
      return Text(
        'Haftalık özeti gör',
        style: tt.bodyMedium?.copyWith(
          color: const Color(0x99FFFFFF),
          fontSize: 14,
        ),
      );
    }

    const userScore = 47;
    const userPosition = 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skorun',
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$userScore',
                  style: tt.displayMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'PTS',
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0x80FFFFFF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Sıran',
              style: tt.bodyMedium?.copyWith(
                color: const Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (userPosition == 1)
                  const Text('🥇', style: TextStyle(fontSize: 28)),
                if (userPosition == 2)
                  const Text('🥈', style: TextStyle(fontSize: 28)),
                if (userPosition == 3)
                  const Text('🥉', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  '#$userPosition',
                  style: tt.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _CardAction({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.f1Red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.edit_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionBadge extends StatelessWidget {
  const _PredictionBadge();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.lockOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
      ),
      child: const Text(
        'TAHMİN YAPILDI',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
