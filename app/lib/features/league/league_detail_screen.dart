import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error_messages.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../../shared/widgets/race_card_new.dart';
import '../calendar/calendar_controller.dart';
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

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          tooltip: 'Geri',
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
          loading: () => const Text('...'),
          error: (error, stackTrace) => const Text('LIG'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Lig ayarları',
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
                  tabs: const [
                    Tab(text: 'SIRALAMA'),
                    Tab(text: 'YARIŞLAR'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _StandingsTab(standingsAsync: standingsAsync)
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
          if (league != null)
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

  String _inviteLinkFor(String inviteCode) => 'gridcall:///join/$inviteCode';

  Future<void> _shareLeague(League league, List<StandingRow> standings) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Paylaşım kartı hazırlanamadı');
      }
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError('Paylaşım görseli oluşturulamadı');
      }

      final fileName = 'gridcall_${league.inviteCode.toLowerCase()}_league.png';

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        subject: '${league.name} ligine katıl',
        text:
            'GridCall ligime katıl: ${_inviteLinkFor(league.inviteCode)}\nDavet kodu: ${league.inviteCode}',
        fileNameOverrides: [fileName],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım hatası: ${friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
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

class _StandingsTab extends StatelessWidget {
  final AsyncValue<List<StandingRow>> standingsAsync;

  const _StandingsTab({required this.standingsAsync});

  @override
  Widget build(BuildContext context) {
    return standingsAsync.when(
      loading: () => const AppLoadingState(label: 'Sıralama yükleniyor'),
      error: (e, _) => AppErrorState(message: friendlyError(e)),
      data: (rows) {
        if (rows.isEmpty) {
          return const AppEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'Henüz puan yok',
            message:
                'İlk yarış sonucundan sonra lig sıralaması burada dolacak.',
          );
        }
        return Column(
          children: [for (final row in rows) _StandingRow(row: row)],
        );
      },
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
    return racesAsync.when(
      loading: () => const AppLoadingState(label: 'Yarışlar yükleniyor'),
      error: (e, _) => AppErrorState(message: friendlyError(e)),
      data: (races) {
        if (races.isEmpty) {
          return const AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Yarış bulunamadı',
            message: 'Bu sezon için gösterilecek yarış takvimi yok.',
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
                label: i == 0 && !visibleRaces[i].raceAt.isAfter(DateTime.now())
                    ? 'Önceki yarış'
                    : 'Sonraki yarış',
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
                  return RaceCardNew(
                    race: race,
                    predictionSaved: predictionSaved,
                    actionLabel:
                        mainStatus == RaceStatus.upcoming ||
                            mainStatus == RaceStatus.locked
                        ? 'Tahmin Yap'
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
                label: const Text('Tüm yarışlar'),
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
      title: 'Yarış seç',
      mainSaved: mainSaved,
      sprintSaved: sprintSaved,
    );
    if (kind == null) return;
    if (closePickerContextBeforeNavigate && sourceContext.mounted) {
      Navigator.of(sourceContext).pop();
    }
    if (!context.mounted) return;
    final entry = (race: race, kind: kind);
    final status = effectiveRaceCardStatus(entry);
    final modeQp = kind == RaceCardKind.sprint ? '?mode=sprint' : '';
    if (status == RaceStatus.finished) {
      context.push('/leagues/$leagueId/race/${race.id}/summary$modeQp');
    } else if (status == RaceStatus.cancelled) {
      context.push('/leagues/$leagueId/race/${race.id}/results$modeQp');
    } else if (status == RaceStatus.live) {
      context.push('/race/${race.id}/live$modeQp');
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
                        child: _SheetHeader(title: 'TÜM YARIŞLAR'),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RaceCardNew(
                          race: race,
                          predictionSaved: mainSaved || sprintSaved,
                          actionLabel: 'Tahmin Yap',
                          actionIcon: Icons.add_circle_outline,
                          onTap: () => _openLeagueRace(
                            pageContext,
                            race,
                            mainSaved: mainSaved,
                            sprintSaved: sprintSaved,
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
                    'DAVET KODU',
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
                'Kopyalandı!',
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
              label: Text(widget.sharing ? 'HAZIRLANIYOR...' : 'LİGİ PAYLAŞ'),
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
  final dynamic row;
  const _StandingRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final rank = row.rank as int;
    final username = row.username as String;
    final score = row.score as int;

    final (rankBg, rankText) = switch (rank) {
      1 => (const Color(0xFFFFD700), Colors.black),
      2 => (const Color(0xFFC0C0C0), Colors.black),
      3 => (const Color(0xFFCD7F32), Colors.black),
      _ => (const Color(0xFF1F1F2E), Colors.white),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: rankText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE10600),
                ),
              ),
              Text(
                'PTS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
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
