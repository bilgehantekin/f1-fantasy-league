import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/race_card_new.dart';
import '../admin/admin_controller.dart';
import '../league/league_action_dialogs.dart';
import '../profile/profile_controller.dart';
import 'calendar_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _scheduledOnce = false;

  Future<void> _onRacesLoaded(List<Race> races) async {
    if (_scheduledOnce) return;
    _scheduledOnce = true;
    final granted = await NotificationService.instance.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bildirim izni verilmedi. Hatırlatmaları ayarlardan açabilirsin.',
          ),
        ),
      );
      return;
    }
    await NotificationService.instance.scheduleForRaces(races);
  }

  @override
  Widget build(BuildContext context) {
    final races = ref.watch(racesProvider);
    final drivers = ref.watch(driverStandingsProvider);
    final constructors = ref.watch(constructorStandingsProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    final profile = ref.watch(profileProvider);

    races.whenData(_onRacesLoaded);
    profile.whenData((p) {
      if (p != null && !p.onboardingCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/onboarding');
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        title: Text(
          'GRIDCALL',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              tooltip: 'Admin - Joker',
              onPressed: () => context.push('/admin/jokers'),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(racesProvider.future),
            ref.refresh(driverStandingsProvider.future),
            ref.refresh(constructorStandingsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          children: [
            const _LeagueActionsPanel(),
            const SizedBox(height: 24),
            _DriverStandingsSection(drivers: drivers),
            const SizedBox(height: 24),
            _ConstructorStandingsSection(constructors: constructors),
            const SizedBox(height: 24),
            _RacesSection(races: races),
          ],
        ),
      ),
    );
  }
}

class _LeagueActionsPanel extends ConsumerWidget {
  const _LeagueActionsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PrimaryLeagueActionCard(
                icon: Icons.emoji_events,
                title: 'LİG OLUŞTUR',
                subtitle: 'Yeni bir lig başlat',
                colors: const [Color(0xFFE10600), Color(0xFFA00500)],
                onTap: () => showCreateLeagueDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryLeagueActionCard(
                icon: Icons.groups,
                title: 'LİGE KATIL',
                subtitle: 'Davet koduyla katıl',
                colors: const [Color(0xFF00D26A), Color(0xFF00A855)],
                onTap: () => showJoinLeagueDialog(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.push('/leagues'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Color(0xFFE10600),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liglerim',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Katıldığın ligleri gör',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryLeagueActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _PrimaryLeagueActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStandingsSection extends StatelessWidget {
  final AsyncValue<List<DriverStanding>> drivers;

  const _DriverStandingsSection({required this.drivers});

  @override
  Widget build(BuildContext context) {
    return _StandingsSection(
      title: 'SÜRÜCÜ SIRALAMASI',
      onViewAll: () => _showFullStandingsSheet(
        context,
        title: 'SÜRÜCÜ SIRALAMASI',
        child: Consumer(
          builder: (context, ref, _) {
            final allDrivers = ref.watch(driverStandingsProvider);
            return allDrivers.when(
              loading: () => const _SectionLoading(),
              error: (e, _) => _SectionError(error: e),
              data: (list) => _FullDriverStandings(drivers: list),
            );
          },
        ),
      ),
      child: drivers.when(
        loading: () => const _SectionLoading(),
        error: (e, _) => _SectionError(error: e),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptySection(text: 'Henüz sıralama yok.');
          }
          return Column(
            children: [
              for (final driver in list.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactDriverCard(driver: driver),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConstructorStandingsSection extends StatelessWidget {
  final AsyncValue<List<ConstructorStanding>> constructors;

  const _ConstructorStandingsSection({required this.constructors});

  @override
  Widget build(BuildContext context) {
    return _StandingsSection(
      title: 'TAKIM SIRALAMASI',
      onViewAll: () => _showFullStandingsSheet(
        context,
        title: 'TAKIM SIRALAMASI',
        child: Consumer(
          builder: (context, ref, _) {
            final allConstructors = ref.watch(constructorStandingsProvider);
            return allConstructors.when(
              loading: () => const _SectionLoading(),
              error: (e, _) => _SectionError(error: e),
              data: (list) => _FullConstructorStandings(constructors: list),
            );
          },
        ),
      ),
      child: constructors.when(
        loading: () => const _SectionLoading(),
        error: (e, _) => _SectionError(error: e),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptySection(text: 'Henüz sıralama yok.');
          }
          return Column(
            children: [
              for (final constructor in list.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactConstructorCard(constructor: constructor),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StandingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onViewAll;

  const _StandingsSection({
    required this.title,
    required this.child,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(title: title),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE10600),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFE10600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RacesSection extends StatelessWidget {
  final AsyncValue<List<Race>> races;

  const _RacesSection({required this.races});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'YARIŞLAR'),
        const SizedBox(height: 12),
        races.when(
          loading: () => const _SectionLoading(),
          error: (e, _) => _SectionError(error: e),
          data: (list) {
            if (list.isEmpty) {
              return const _EmptySection(
                text: 'Bu sezon için yarış bulunamadı.',
              );
            }
            final visibleRaces = buildPreviousAndNextRaces(list);
            return Column(
              children: [
                for (var i = 0; i < visibleRaces.length; i++) ...[
                  _RaceScopeLabel(
                    label:
                        i == 0 &&
                            !visibleRaces[i].raceAt.isAfter(DateTime.now())
                        ? 'Önceki yarış'
                        : 'Sonraki yarış',
                  ),
                  const SizedBox(height: 8),
                  RaceCardNew(
                    race: visibleRaces[i],
                    showLeagueContext: false,
                    onTap: () => _openCalendarRace(context, visibleRaces[i]),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAllRacesSheet(context, list),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Tüm yarışlar'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openCalendarRace(
    BuildContext context,
    Race race, {
    BuildContext? pickerContext,
    bool closePickerContextBeforeNavigate = false,
  }) async {
    final sourceContext = pickerContext ?? context;
    final kind = await showRaceKindPicker(
      sourceContext,
      race: race,
      title: 'Yarış seç',
    );
    if (kind == null) return;
    if (closePickerContextBeforeNavigate && sourceContext.mounted) {
      Navigator.of(sourceContext).pop();
    }
    if (!context.mounted) return;
    final entry = (race: race, kind: kind);
    final status = effectiveRaceCardStatus(entry);
    final modeQp = kind == RaceCardKind.sprint ? '?mode=sprint' : '';
    if (status == RaceStatus.finished || status == RaceStatus.cancelled) {
      context.push('/race/${race.id}/results$modeQp');
    } else if (status == RaceStatus.live) {
      context.push('/race/${race.id}/live$modeQp');
    } else {
      context.push('/race/${race.id}/lineup$modeQp');
    }
  }

  void _showAllRacesSheet(BuildContext context, List<Race> races) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sorted = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 8, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _SectionHeader(title: 'TÜM YARIŞLAR'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final race = sorted[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RaceCardNew(
                          race: race,
                          showLeagueContext: false,
                          onTap: () => _openCalendarRace(
                            pageContext,
                            race,
                            pickerContext: sheetContext,
                            closePickerContextBeforeNavigate: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RaceScopeLabel extends StatelessWidget {
  final String label;

  const _RaceScopeLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0x99FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

void _showFullStandingsSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 8, 12),
                child: Row(
                  children: [
                    Expanded(child: _SectionHeader(title: title)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: child,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _FullDriverStandings extends StatelessWidget {
  final List<DriverStanding> drivers;

  const _FullDriverStandings({required this.drivers});

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const _EmptySection(text: 'Henüz sıralama yok.');
    }
    return Column(
      children: [
        for (final driver in drivers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CompactDriverCard(driver: driver),
          ),
      ],
    );
  }
}

class _FullConstructorStandings extends StatelessWidget {
  final List<ConstructorStanding> constructors;

  const _FullConstructorStandings({required this.constructors});

  @override
  Widget build(BuildContext context) {
    if (constructors.isEmpty) {
      return const _EmptySection(text: 'Henüz sıralama yok.');
    }
    return Column(
      children: [
        for (final constructor in constructors)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CompactConstructorCard(constructor: constructor),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE10600),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _CompactDriverCard extends StatelessWidget {
  final DriverStanding driver;

  const _CompactDriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PositionText(position: driver.position),
          const SizedBox(width: 12),
          _Medal(position: driver.position),
          const SizedBox(width: 12),
          _ColorBar(color: driver.teamColor, width: 4, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    driver.code,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  driver.teamName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _PointsText(points: driver.points, fontSize: 20),
        ],
      ),
    );
  }
}

class _CompactConstructorCard extends StatelessWidget {
  final ConstructorStanding constructor;

  const _CompactConstructorCard({required this.constructor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PositionText(position: constructor.position),
          const SizedBox(width: 12),
          _Medal(position: constructor.position),
          const SizedBox(width: 12),
          _ColorBar(color: constructor.color, width: 6, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              constructor.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _PointsText(points: constructor.points, fontSize: 24),
        ],
      ),
    );
  }
}

class _PositionText extends StatelessWidget {
  final int position;

  const _PositionText({required this.position});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        '$position',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  final int position;

  const _Medal({required this.position});

  @override
  Widget build(BuildContext context) {
    final medal = switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '',
    };
    return SizedBox(
      width: 20,
      child: Text(medal, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _ColorBar extends StatelessWidget {
  final String color;
  final double width;
  final double height;

  const _ColorBar({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _parseHexColor(color),
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }
}

class _PointsText extends StatelessWidget {
  final int points;
  final double fontSize;

  const _PointsText({required this.points, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$points',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFE10600),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingState(label: 'Veriler yükleniyor');
  }
}

class _SectionError extends StatelessWidget {
  final Object error;

  const _SectionError({required this.error});

  @override
  Widget build(BuildContext context) {
    return AppErrorState(message: friendlyError(error));
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.sports_score_outlined,
      title: 'Henüz veri yok',
      message: text,
    );
  }
}

Color _parseHexColor(String value) {
  final hex = value.replaceAll('#', '').trim();
  if (hex.length != 6) return Colors.white;
  return Color(int.parse('0xFF$hex'));
}
