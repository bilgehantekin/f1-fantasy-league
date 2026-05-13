import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error_messages.dart';
import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models.dart';
import '../../shared/turkish_text.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/premium_stats_icon.dart';
import '../../shared/widgets/race_card_new.dart';
import '../calendar/calendar_controller.dart';
import '../premium/premium_service.dart';
import 'league_controller.dart';
import 'league_share_card.dart';

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueId;
  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _shareCardKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueProvider(widget.leagueId));
    final standingsAsync = ref.watch(seasonStandingsProvider(widget.leagueId));
    final racesAsync = ref.watch(racesProvider);
    final predictionStatusAsync = ref.watch(
      leaguePredictionStatusProvider(widget.leagueId),
    );
    final tt = Theme.of(context).textTheme;
    final league = leagueAsync.asData?.value;
    final standings = standingsAsync.asData?.value ?? <StandingRow>[];
    final l = AppLocalizations.of(context);
    final isPremium = ref.watch(effectiveIsPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          tooltip: l.back,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/calendar'),
        ),
        title: leagueAsync.when(
          data: (l) => Text(
            l.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          loading: () => Text(l.appLoading),
          error: (error, stackTrace) => Text(l.leagueFallback.toUpperCase()),
        ),
        actions: [
          if (Env.enablePremium) ...[
            IconButton(
              icon: const PremiumStatsIcon(size: 30),
              tooltip: l.detailedLeagueStats,
              onPressed: () =>
                  context.push('/leagues/${widget.leagueId}/stats'),
            ),
          ],
          if (Env.enablePremium && isPremium) ...[
            IconButton(
              icon: Icon(
                league?.isFavorite == true ? Icons.star : Icons.star_border,
                size: 22,
                color: league?.isFavorite == true
                    ? const Color(0xFFFFD166)
                    : null,
              ),
              tooltip: league?.isFavorite == true
                  ? l.unfavoriteLeague
                  : l.favoriteLeague,
              onPressed: league == null ? null : () => _toggleFavorite(league),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: l.leagueSettingsTooltip,
            onPressed: () =>
                context.push('/leagues/${widget.leagueId}/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            children: [
              // Invite Code Card
              leagueAsync.maybeWhen(
                data: (l) => _InviteCodeCard(
                  league: l,
                  sharing: _sharing,
                  onShare: () => _shareLeague(l, standings),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFE10600),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0x99FFFFFF),
                  labelStyle: tt.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: tt.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: l.standings),
                    Tab(text: l.leagueTabRaces),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _StandingsTab(
                          leagueId: widget.leagueId,
                          standingsAsync: standingsAsync,
                          racesAsync: racesAsync,
                        )
                      : _RacesTab(
                          racesAsync: racesAsync,
                          predictionStatusAsync: predictionStatusAsync,
                          leagueId: widget.leagueId,
                        );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_sharing && league != null)
            Positioned(
              left: -1400,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: LeagueShareCard(
                  league: league,
                  standings: standings,
                  inviteLink: _inviteLinkFor(league.inviteCode),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _inviteLinkFor(String inviteCode) =>
      Env.joinUri(inviteCode).toString();

  Future<void> _shareLeague(League league, List<StandingRow> standings) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final l = AppLocalizations.of(context);
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError(l.shareCardCouldNotBePrepared);
      }
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError(l.shareImageCouldNotBeCreated);
      }

      final fileName = 'gridcall_${league.inviteCode.toLowerCase()}_league.png';

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        subject: AppLocalizations.of(context).joinLeagueSubject(league.name),
        text: AppLocalizations.of(context).joinLeagueShareText(
          _inviteLinkFor(league.inviteCode),
          league.inviteCode,
        ),
        fileNameOverrides: [fileName],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).shareError(friendlyError(e)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _toggleFavorite(League league) async {
    try {
      await setLeagueFavorite(league.id, !league.isFavorite);
      ref.invalidate(leagueProvider(widget.leagueId));
      ref.invalidate(myLeaguesProvider);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();
      if (raw.contains('premium_required')) {
        if (Env.enablePremium) {
          context.push('/premium');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).lockedPremiumStats),
            ),
          );
        }
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class _InviteCodeCard extends StatefulWidget {
  final League league;
  final bool sharing;
  final VoidCallback onShare;

  const _InviteCodeCard({
    required this.league,
    required this.sharing,
    required this.onShare,
  });

  @override
  State<_InviteCodeCard> createState() => _InviteCodeCardState();
}

class _StandingsTab extends ConsumerStatefulWidget {
  final String leagueId;
  final AsyncValue<List<StandingRow>> standingsAsync;
  final AsyncValue<List<Race>> racesAsync;

  const _StandingsTab({
    required this.leagueId,
    required this.standingsAsync,
    required this.racesAsync,
  });

  @override
  ConsumerState<_StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends ConsumerState<_StandingsTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(currentUserProvider)?.id;
    final myIsPremium = ref.watch(effectiveIsPremiumProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StandingsSegmentedControl(
          selectedIndex: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selectedIndex == 0
              ? _GeneralStandings(
                  standingsAsync: widget.standingsAsync,
                  racesAsync: widget.racesAsync,
                  leagueId: widget.leagueId,
                  myUserId: myUserId,
                  myIsPremium: myIsPremium,
                )
              : _WeeklyStandings(
                  leagueId: widget.leagueId,
                  racesAsync: widget.racesAsync,
                  myUserId: myUserId,
                  myIsPremium: myIsPremium,
                ),
        ),
      ],
    );
  }
}

class _StandingsSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _StandingsSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppLocalizations.of(context).overall,
      AppLocalizations.of(context).thisWeek,
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          _StandingsSegmentButton(
            label: labels[i],
            selected: selectedIndex == i,
            onTap: () => onChanged(i),
          ),
          if (i != labels.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StandingsSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StandingsSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.f1Red.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.f1Red
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: selected
                  ? AppColors.f1Red
                  : Colors.white.withValues(alpha: 0.62),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneralStandings extends StatelessWidget {
  final String leagueId;
  final AsyncValue<List<StandingRow>> standingsAsync;
  final AsyncValue<List<Race>> racesAsync;
  final String? myUserId;
  final bool myIsPremium;

  const _GeneralStandings({
    required this.leagueId,
    required this.standingsAsync,
    required this.racesAsync,
    required this.myUserId,
    required this.myIsPremium,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return standingsAsync.when(
      loading: () => AppLoadingState(label: l.standingsLoading),
      error: (e, _) => AppErrorState(message: friendlyError(e)),
      data: (rows) => Consumer(
        builder: (context, ref, _) {
          final latestEvent = racesAsync.asData == null
              ? null
              : _latestScoredEvent(racesAsync.asData!.value);
          final previousAsync = latestEvent == null
              ? null
              : ref.watch(
                  previousSeasonStandingsProvider(
                    PreviousStandingsKey(
                      leagueId: leagueId,
                      cutoff: latestEvent.at,
                    ),
                  ),
                );
          final previousRows =
              previousAsync?.asData?.value ?? const <StandingRow>[];
          return _StandingsList(
            rows: rows,
            myUserId: myUserId,
            myIsPremium: myIsPremium,
            rankDeltas: _rankDeltas(rows, previousRows),
            emptyTitle: l.noPointsYet,
            emptyMessage: l.leagueShareEmpty,
          );
        },
      ),
    );
  }
}

class _WeeklyStandings extends ConsumerWidget {
  final String leagueId;
  final AsyncValue<List<Race>> racesAsync;
  final String? myUserId;
  final bool myIsPremium;

  const _WeeklyStandings({
    required this.leagueId,
    required this.racesAsync,
    required this.myUserId,
    required this.myIsPremium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return racesAsync.when(
      loading: () => AppLoadingState(label: l.weeklyStandingsLoading),
      error: (e, _) => AppErrorState(message: friendlyError(e)),
      data: (races) {
        final weeklyRace = _weeklyRaceFor(races);
        if (weeklyRace == null) {
          return AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: l.raceNotFound,
            message: l.noWeeklyRaceFound,
          );
        }
        final key = WeeklySummaryKey(
          leagueId: leagueId,
          raceId: weeklyRace.race.id,
          sprint: weeklyRace.sprint,
        );
        final standingsAsync = ref.watch(
          weeklyRace.weekend
              ? weeklyWeekendStandingsProvider(key)
              : weeklyStandingsProvider(key),
        );
        return standingsAsync.when(
          loading: () => AppLoadingState(label: l.weeklyStandingsLoading),
          error: (e, _) => AppErrorState(message: friendlyError(e)),
          data: (rows) => _StandingsList(
            rows: rows,
            myUserId: myUserId,
            myIsPremium: myIsPremium,
            emptyTitle: l.noPointsThisWeek,
            emptyMessage: l.weeklyScoresCalculated(weeklyRace.race.name),
          ),
        );
      },
    );
  }

  ({Race race, bool sprint, bool weekend})? _weeklyRaceFor(List<Race> races) {
    if (races.isEmpty) return null;
    final now = DateTime.now();
    final sorted = [...races]..sort((a, b) => a.raceAt.compareTo(b.raceAt));
    ({Race race, bool sprint, bool weekend})? latestStarted;
    DateTime? latestAt;

    void consider(Race race, {required bool sprint, required DateTime? at}) {
      if (at == null) return;
      final finished = sprint
          ? race.sprintStatus == RaceStatus.finished
          : race.status == RaceStatus.finished;
      if (at.isAfter(now) && !finished) return;
      if (latestAt == null || at.isAfter(latestAt!)) {
        latestAt = at;
        latestStarted = (
          race: race,
          sprint: sprint,
          weekend: race.hasSprint && race.status == RaceStatus.finished,
        );
      }
    }

    for (final race in sorted) {
      consider(race, sprint: true, at: race.sprintRaceAt);
      consider(race, sprint: false, at: race.raceAt);
    }
    if (latestStarted != null) return latestStarted;
    final first = sorted.first;
    return (
      race: first,
      sprint: first.hasSprint && first.sprintRaceAt != null,
      weekend: first.hasSprint,
    );
  }
}

({Race race, bool sprint, DateTime at})? _latestScoredEvent(List<Race> races) {
  ({Race race, bool sprint, DateTime at})? latest;

  void consider(Race race, {required bool sprint, required DateTime? at}) {
    if (at == null) return;
    final finished = sprint
        ? race.sprintStatus == RaceStatus.finished
        : race.status == RaceStatus.finished;
    if (!finished) return;
    if (latest == null || at.isAfter(latest!.at)) {
      latest = (race: race, sprint: sprint, at: at);
    }
  }

  for (final race in races) {
    consider(race, sprint: true, at: race.sprintRaceAt);
    consider(race, sprint: false, at: race.raceAt);
  }
  return latest;
}

Map<String, int> _rankDeltas(
  List<StandingRow> currentRows,
  List<StandingRow> previousRows,
) {
  final previousByUser = {for (final row in previousRows) row.userId: row.rank};
  return {
    for (final row in currentRows)
      if (previousByUser.containsKey(row.userId))
        row.userId: previousByUser[row.userId]! - row.rank,
  };
}

class _StandingsList extends StatelessWidget {
  final List<StandingRow> rows;
  final String? myUserId;
  final bool myIsPremium;
  final Map<String, int> rankDeltas;
  final String emptyTitle;
  final String emptyMessage;

  const _StandingsList({
    required this.rows,
    required this.myUserId,
    required this.myIsPremium,
    this.rankDeltas = const {},
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.leaderboard_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return Column(
      children: [
        for (final row in rows)
          _StandingRow(
            row: row,
            isMe: row.userId == myUserId,
            isPremium:
                row.userId == myUserId ? myIsPremium || row.isPremium : row.isPremium,
            rankDelta: rankDeltas[row.userId] ?? 0,
          ),
      ],
    );
  }
}

class _RacesTab extends StatelessWidget {
  final AsyncValue<List<Race>> racesAsync;
  final AsyncValue<LeaguePredictionStatus> predictionStatusAsync;
  final String leagueId;

  const _RacesTab({
    required this.racesAsync,
    required this.predictionStatusAsync,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return racesAsync.when(
      loading: () => AppLoadingState(label: l.racesLoading),
      error: (e, _) => AppErrorState(message: friendlyError(e)),
      data: (races) {
        if (races.isEmpty) {
          return AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: l.raceNotFound,
            message: l.noRaceCalendarForSeason,
          );
        }
        final visibleRaces = buildPreviousAndNextRaces(races);
        final predictionStatus =
            predictionStatusAsync.asData?.value ??
            const LeaguePredictionStatus.empty();
        return Column(
          children: [
            for (var i = 0; i < visibleRaces.length; i++) ...[
              _RaceScopeLabel(
                label: i == 0 && countsAsPreviousRace(visibleRaces[i])
                    ? l.previousRace
                    : l.nextRace,
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final race = visibleRaces[i];
                  final mainStatus = effectiveRaceCardStatus((
                    race: race,
                    kind: RaceCardKind.main,
                  ));
                  final mainSaved = predictionStatus.savedFor(
                    race.id,
                    sprint: false,
                  );
                  final sprintSaved = predictionStatus.savedFor(
                    race.id,
                    sprint: true,
                  );
                  final predictionSaved = mainSaved || sprintSaved;
                  final savedPredictionCount =
                      (mainSaved ? 1 : 0) + (sprintSaved ? 1 : 0);
                  final totalPredictionCount = race.hasSprint ? 2 : 1;
                  return RaceCardNew(
                    race: race,
                    predictionSaved: predictionSaved,
                    savedPredictionCount: savedPredictionCount,
                    totalPredictionCount: totalPredictionCount,
                    keepStartLightsVisible: true,
                    actionLabel:
                        mainStatus == RaceStatus.upcoming ||
                            mainStatus == RaceStatus.locked
                        ? l.makePrediction
                        : null,
                    actionIcon: Icons.add_circle_outline,
                    onTap: () => _openLeagueRace(
                      context,
                      race,
                      mainSaved: mainSaved,
                      sprintSaved: sprintSaved,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showAllLeagueRacesSheet(context, races, predictionStatus),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(l.allRaces),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openLeagueRace(
    BuildContext context,
    Race race, {
    required bool mainSaved,
    required bool sprintSaved,
    BuildContext? pickerContext,
    bool closePickerContextBeforeNavigate = false,
  }) async {
    final sourceContext = pickerContext ?? context;
    final kind = await showRaceKindPicker(
      sourceContext,
      race: race,
      title: AppLocalizations.of(context).selectRace,
      mainSaved: mainSaved,
      sprintSaved: sprintSaved,
    );
    if (kind == null) return;
    if (closePickerContextBeforeNavigate && sourceContext.mounted) {
      Navigator.of(sourceContext).pop();
    }
    if (!context.mounted) return;
    final entry = (race: race, kind: kind);
    final status = effectiveRaceCardNavigationStatus(entry);
    final modeQp = kind == RaceCardKind.sprint ? '?mode=sprint' : '';
    if (status == RaceStatus.finished) {
      context.push('/leagues/$leagueId/race/${race.id}/summary$modeQp');
    } else if (status == RaceStatus.cancelled) {
      context.push('/leagues/$leagueId/race/${race.id}/results$modeQp');
    } else if (status == RaceStatus.live) {
      final liveSeparator = modeQp.isEmpty ? '?' : '&';
      context.push(
        '/race/${race.id}/live$modeQp${liveSeparator}league=$leagueId',
      );
    } else {
      context.push('/leagues/$leagueId/race/${race.id}/predict$modeQp');
    }
  }

  void _showAllLeagueRacesSheet(
    BuildContext context,
    List<Race> races,
    LeaguePredictionStatus predictionStatus,
  ) {
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
        final pinnedRaceIds = buildPreviousAndNextRaces(
          races,
        ).map((race) => race.id).toSet();
        // Sadece bir sonraki yarış "tahminlere açık" görünsün; diğer ileri
        // tarihliler kilitli olarak listelenir ve "Tahmin yap" butonu
        // gizlenir.
        final firstUpcomingId = buildPreviousAndNextRaces(
          races,
        ).where((race) => !countsAsPreviousRace(race)).map((r) => r.id).firstOrNull;
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
                      Expanded(
                        child: _SheetHeader(
                          title: AppLocalizations.of(context).allRacesUpper,
                        ),
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
                      final mainSaved = predictionStatus.savedFor(
                        race.id,
                        sprint: false,
                      );
                      final sprintSaved = predictionStatus.savedFor(
                        race.id,
                        sprint: true,
                      );
                      final savedPredictionCount =
                          (mainSaved ? 1 : 0) + (sprintSaved ? 1 : 0);
                      final totalPredictionCount = race.hasSprint ? 2 : 1;
                      final isFirstUpcoming = race.id == firstUpcomingId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RaceCardNew(
                          race: race,
                          predictionSaved: mainSaved || sprintSaved,
                          savedPredictionCount: savedPredictionCount,
                          totalPredictionCount: totalPredictionCount,
                          keepStartLightsVisible: pinnedRaceIds.contains(
                            race.id,
                          ),
                          forceLocked: !isFirstUpcoming,
                          actionLabel: AppLocalizations.of(
                            context,
                          ).makePrediction,
                          actionIcon: Icons.add_circle_outline,
                          onTap: () => _openLeagueRace(
                            pageContext,
                            race,
                            mainSaved: mainSaved,
                            sprintSaved: sprintSaved,
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
        turkishUpper(label, context: context),
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

class _SheetHeader extends StatelessWidget {
  final String title;

  const _SheetHeader({required this.title});

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

class _InviteCodeCardState extends State<_InviteCodeCard> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F2E), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).inviteCode,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.league.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE10600),
                      letterSpacing: 4.8,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.content_copy, size: 20),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.league.inviteCode),
                  );
                  setState(() => _copied = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _copied = false);
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1F1F2E),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          if (_copied)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppLocalizations.of(context).copied,
                style: TextStyle(fontSize: 12, color: const Color(0xFF00D26A)),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.sharing ? null : widget.onShare,
              icon: widget.sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share, size: 18),
              label: Text(
                widget.sharing
                    ? AppLocalizations.of(context).preparing
                    : AppLocalizations.of(context).shareLeague,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE10600),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF5E5E72),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final StandingRow row;
  final bool isMe;
  final bool isPremium;
  final int rankDelta;

  const _StandingRow({
    required this.row,
    required this.isMe,
    required this.isPremium,
    required this.rankDelta,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (row.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC8CDD3),
      3 => const Color(0xFFD08B5B),
      _ => Colors.white.withValues(alpha: 0.72),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.f1Red.withValues(alpha: 0.16)
            : AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.f1Red : Colors.white.withValues(alpha: 0.07),
          width: isMe ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '${row.rank}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isMe ? AppColors.f1Red : rankColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      row.username,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isPremium
                            ? const Color(0xFFFFD166)
                            : Colors.white,
                        shadows: isPremium
                            ? const [
                                Shadow(
                                  color: Color(0xFF3A2A08),
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).you,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                      color: AppColors.f1Red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          _RankChangeChip(delta: rankDelta),
          const SizedBox(width: 18),
          SizedBox(
            width: 56,
            child: Text(
              '${row.score}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankChangeChip extends StatelessWidget {
  final int delta;

  const _RankChangeChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final isDown = delta < 0;
    final color = isUp
        ? AppColors.lockGreen
        : isDown
        ? AppColors.f1Red
        : Colors.white.withValues(alpha: 0.42);
    final label = delta == 0 ? '—' : '${isUp ? '+' : ''}$delta';
    return Container(
      width: 54,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: delta == 0 ? 20 : 15,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
