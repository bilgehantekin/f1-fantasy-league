import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../shared/models.dart';
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
          onPressed: () => Navigator.of(context).pop(),
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

  String _inviteLinkFor(String inviteCode) => 'pitwall:///join/$inviteCode';

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

      final fileName = 'pitwall_${league.inviteCode.toLowerCase()}_league.png';

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: '${league.name} · PitWall',
          subject: '${league.name} ligine katıl',
          text:
              'PitWall ligime katıl: ${_inviteLinkFor(league.inviteCode)}\nDavet kodu: ${league.inviteCode}',
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paylaşım hatası: $e')));
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
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Hata: $e')),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Henüz puan yok. İlk yarış sonucundan sonra dolacak.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
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
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Hata: $e')),
      ),
      data: (races) {
        if (races.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Bu sezon için yarış bulunamadı.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          );
        }
        // Sıra: bu haftaki etkinlikler üstte → bitmiş/iptal eski → yeni →
        // gelecek yarışlar yakın → uzak.
        final cards = buildOrderedRaceCards(races);
        final predictionStatus =
            predictionStatusAsync.asData?.value ??
            const LeaguePredictionStatus.empty();
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Builder(
                builder: (context) {
                  final entry = cards[i];
                  final race = entry.race;
                  final isSprint = entry.kind == RaceCardKind.sprint;
                  final status = isSprint ? race.sprintStatus : race.status;
                  final modeQp = isSprint ? '?mode=sprint' : '';
                  return RaceCardNew(
                    race: race,
                    kind: entry.kind,
                    predictionSaved: predictionStatus.savedFor(
                      race.id,
                      sprint: isSprint,
                    ),
                    onTap: () {
                      if (status == RaceStatus.finished) {
                        if (isSprint) {
                          context.push(
                            '/leagues/$leagueId/race/${race.id}/results$modeQp',
                          );
                        } else {
                          context.push(
                            '/leagues/$leagueId/race/${race.id}/summary',
                          );
                        }
                      } else if (status == RaceStatus.cancelled) {
                        context.push(
                          '/leagues/$leagueId/race/${race.id}/results$modeQp',
                        );
                      } else if (status == RaceStatus.live) {
                        context.push('/race/${race.id}/live$modeQp');
                      } else {
                        context.push(
                          '/leagues/$leagueId/race/${race.id}/predict$modeQp',
                        );
                      }
                    },
                  );
                },
              ),
              if (i < cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
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
