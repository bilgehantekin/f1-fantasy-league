import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/race_card_new.dart';
import '../../shared/turkish_text.dart';
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
    final reminders = await ReminderPreferences.load();
    final postRace = await PostRaceSummaryPreferences.load();
    if (!reminders.enabled && !postRace.enabled) {
      await NotificationService.instance.scheduleForRaces(
        races,
        preferences: reminders,
        postRacePreferences: postRace,
      );
      return;
    }
    final granted = await NotificationService.instance.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).notificationDeniedLater),
        ),
      );
      return;
    }
    await NotificationService.instance.scheduleForRaces(
      races,
      preferences: reminders,
      postRacePreferences: postRace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final races = ref.watch(racesProvider);
    final drivers = ref.watch(driverStandingsProvider);
    final constructors = ref.watch(constructorStandingsProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    final profile = ref.watch(profileProvider);
    final l = AppLocalizations.of(context);

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
              tooltip: l.adminJokerTooltip,
              onPressed: () => context.push('/admin/jokers'),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            tooltip: l.profileTooltip,
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
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _HomePrimaryActionCard(
                  title: l.newLeague,
                  subtitle: l.createYourOwnLeague,
                  buttonLabel: l.create,
                  icon: Icons.add_circle_outline,
                  emphasis: _ActionEmphasis.solid,
                  onTap: () => showCreateLeagueDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomePrimaryActionCard(
                  title: l.join,
                  subtitle: l.joinWithInviteCode,
                  buttonLabel: l.enterCode,
                  icon: Icons.qr_code_scanner_rounded,
                  emphasis: _ActionEmphasis.tinted,
                  onTap: () => showJoinLeagueDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HomeWideActionCard(
          title: l.myLeagues,
          subtitle: l.viewYourLeagues,
          icon: Icons.emoji_events_rounded,
          onTap: () => context.push('/leagues'),
        ),
      ],
    );
  }
}

enum _ActionEmphasis { solid, tinted }

class _HomePrimaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final _ActionEmphasis emphasis;
  final VoidCallback onTap;

  const _HomePrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.emphasis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isSolid = emphasis == _ActionEmphasis.solid;
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.f1Red.withValues(alpha: 0.10),
          highlightColor: AppColors.f1Red.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.f1Red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.f1Red),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionPill(label: buttonLabel, solid: isSolid),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final bool solid;

  const _ActionPill({required this.label, required this.solid});

  @override
  Widget build(BuildContext context) {
    final bg = solid
        ? AppColors.f1Red
        : AppColors.f1Red.withValues(alpha: 0.12);
    final fg = solid ? Colors.white : AppColors.f1Red;
    final border = solid
        ? null
        : Border.all(
            color: AppColors.f1Red.withValues(alpha: 0.35),
            width: 1,
          );
    return Container(
      width: double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 14, color: fg),
        ],
      ),
    );
  }
}

class _HomeWideActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeWideActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.f1Red.withValues(alpha: 0.10),
          highlightColor: AppColors.f1Red.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.f1Red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: AppColors.f1Red,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.f1Red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.f1Red,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final l = AppLocalizations.of(context);
    return _StandingsSection(
      title: l.calendarDriverStandings,
      onViewAll: () => _showFullStandingsSheet(
        context,
        title: l.calendarDriverStandings,
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
            return _EmptySection(text: l.noStandingsYet);
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
    final l = AppLocalizations.of(context);
    return _StandingsSection(
      title: l.calendarConstructorStandings,
      onViewAll: () => _showFullStandingsSheet(
        context,
        title: l.calendarConstructorStandings,
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
            return _EmptySection(text: l.noStandingsYet);
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
    final l = AppLocalizations.of(context);
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.all,
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
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: AppLocalizations.of(context).races),
        const SizedBox(height: 12),
        races.when(
          loading: () => const _SectionLoading(),
          error: (e, _) => _SectionError(error: e),
          data: (list) {
            if (list.isEmpty) {
              return _EmptySection(text: l.noRacesForSeason);
            }
            final visibleRaces = buildPreviousAndNextRaces(list);
            return Column(
              children: [
                for (var i = 0; i < visibleRaces.length; i++) ...[
                  _RaceScopeLabel(
                    label: i == 0 && countsAsPreviousRace(visibleRaces[i])
                        ? l.previousRace
                        : l.nextRace,
                  ),
                  const SizedBox(height: 8),
                  RaceCardNew(
                    race: visibleRaces[i],
                    showLeagueContext: false,
                    keepStartLightsVisible: true,
                    onTap: () => _openCalendarRace(context, visibleRaces[i]),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAllRacesSheet(context, list),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(l.allRaces),
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
      title: AppLocalizations.of(context).selectRace,
    );
    if (kind == null) return;
    if (closePickerContextBeforeNavigate && sourceContext.mounted) {
      Navigator.of(sourceContext).pop();
    }
    if (!context.mounted) return;
    final entry = (race: race, kind: kind);
    final status = effectiveRaceCardNavigationStatus(entry);
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
    final l = AppLocalizations.of(pageContext);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sorted = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
        final pinnedRaceIds = buildPreviousAndNextRaces(
          races,
        ).map((race) => race.id).toSet();
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
                      Expanded(child: _SectionHeader(title: l.allRaces)),
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
                          keepStartLightsVisible: pinnedRaceIds.contains(
                            race.id,
                          ),
                          onTap: () => _openCalendarRace(pageContext, race),
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
        turkishUpper(label),
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
      return _EmptySection(text: AppLocalizations.of(context).noStandingsYet);
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
      return _EmptySection(text: AppLocalizations.of(context).noStandingsYet);
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
    final l = AppLocalizations.of(context);
    return AppLoadingState(label: l.dataLoading);
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
    final l = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.sports_score_outlined,
      title: l.noDataYet,
      message: text,
    );
  }
}

Color _parseHexColor(String value) {
  final hex = value.replaceAll('#', '').trim();
  if (hex.length != 6) return Colors.white;
  return Color(int.parse('0xFF$hex'));
}
