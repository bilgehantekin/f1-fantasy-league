import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error_messages.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../prediction/prediction_controller.dart';
import 'league_controller.dart';
import 'weekly_summary_share_card.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String raceId;
  final bool sprintMode;

  const WeeklySummaryScreen({
    super.key,
    required this.leagueId,
    required this.raceId,
    this.sprintMode = false,
  });

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueProvider(widget.leagueId));
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final summaryAsync = ref.watch(
      weeklySummaryProvider(
        WeeklySummaryKey(
          leagueId: widget.leagueId,
          raceId: widget.raceId,
          sprint: widget.sprintMode,
        ),
      ),
    );

    final league = leagueAsync.asData?.value;
    final race = raceAsync.asData?.value;
    final summary = summaryAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        title: const Text('HAFTALIK ÖZET'),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share, size: 20),
            onPressed: (league == null || race == null || summary == null)
                ? null
                : () => _share(league, race, summary),
          ),
        ],
      ),
      body: Stack(
        children: [
          leagueAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: ${friendlyError(e)}')),
            data: (league) => raceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: ${friendlyError(e)}')),
              data: (race) => summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Hata: ${friendlyError(e)}')),
                data: (summary) => _Body(
                  league: league,
                  race: race,
                  summary: summary,
                  sprintMode: widget.sprintMode,
                ),
              ),
            ),
          ),
          if (league != null && race != null && summary != null)
            Positioned(
              left: -1400,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: WeeklySummaryShareCard(
                  league: league,
                  race: race,
                  summary: summary,
                  sprintMode: widget.sprintMode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _share(
    League league,
    Race race,
    LeagueWeeklySummary summary,
  ) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
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

      final fileName =
          'pitwall_${league.inviteCode.toLowerCase()}_'
          'r${race.round}'
          '${widget.sprintMode ? '_sprint' : ''}.png';
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject: '${league.name} · ${race.name} özeti',
        text: _shareText(league.name, race.name, summary),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
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

  static String _shareText(
    String leagueName,
    String raceName,
    LeagueWeeklySummary summary,
  ) {
    final winner = summary.bestPrediction == null
        ? 'Henüz skor yok'
        : '${summary.bestPrediction!.username} (${summary.bestPrediction!.score} puan)';
    return '$leagueName · $raceName\nKazanan: $winner\nPitWall';
  }
}

class _Body extends StatelessWidget {
  final League league;
  final Race race;
  final LeagueWeeklySummary summary;
  final bool sprintMode;

  const _Body({
    required this.league,
    required this.race,
    required this.summary,
    required this.sprintMode,
  });

  @override
  Widget build(BuildContext context) {
    final leagueId = league.id;
    final raceId = race.id;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${league.name.toUpperCase()} · R${race.round}'
          '${sprintMode ? ' · Sprint' : ''}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.f1Red,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          race.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'HAFTANIN KAZANANI',
                value: summary.bestPrediction?.username ?? '-',
                subvalue: summary.bestPrediction == null
                    ? 'Henüz skor yok'
                    : '${summary.bestPrediction!.score} puan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: sprintMode ? 'TAHMİN SAYISI' : 'JOKER BİLENLER',
                value: sprintMode
                    ? '${summary.predictionCount}'
                    : '${summary.jokerHitCount}',
                subvalue: sprintMode ? 'tahmin' : 'kişi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'EN ÇOK SEÇİLEN SÜRÜCÜ',
          value: summary.mostPickedDriver?.code ?? '-',
          subvalue: summary.mostPickedDriver == null
              ? 'Tahmin yok'
              : '${summary.mostPickedDriver!.fullName} · ${summary.mostPickedDriver!.pickCount} seçim',
          accentColor: summary.mostPickedDriver?.color,
        ),
        const SizedBox(height: 24),
        const _SectionTitle(label: 'İLK 5'),
        const SizedBox(height: 12),
        if (summary.topStandings.isEmpty)
          const _EmptyState()
        else
          for (final row in summary.topStandings)
            _SummaryStandingRow(
              rank: row.rank,
              username: row.username,
              score: row.score,
            ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(
            '/leagues/$leagueId/race/$raceId/results'
            '${sprintMode ? '?mode=sprint' : ''}',
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('DETAYLI SONUÇLARI GÖR'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;
  final String? accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subvalue,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor == null
        ? AppColors.f1Red
        : Color(int.parse(accentColor!.replaceAll('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0x99FFFFFF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStandingRow extends StatelessWidget {
  final int rank;
  final String username;
  final int score;

  const _SummaryStandingRow({
    required this.rank,
    required this.username,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.f1Red,
              ),
            ),
          ),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$score PTS',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Row(
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
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'Bu yarış için ligde skorlanmış tahmin bulunamadı.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0x99FFFFFF)),
    ),
  );
}
