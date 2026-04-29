import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final myBadgesAsync = ref.watch(myBadgesProvider);
    final categoriesAsync = ref.watch(categoryAccuracyProvider);
    final trendAsync = ref.watch(seasonTrendProvider);
    final driverAccAsync = ref.watch(driverAccuracyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFİL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (p) {
          if (p == null) return const Center(child: Text('Giriş gerekli'));
          final isPremium = p.isPremium;
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            children: [
              _Header(profile: p),
              if (!isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () => context.push('/premium'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.f1Red,
                          AppColors.f1Red.withValues(alpha: 0.7),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text('Premium\'a yükselt',
                                  style: Theme.of(context).textTheme.titleMedium)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('PREMIUM',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFFFFD700),
                                  letterSpacing: 2,
                                )),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/premium'),
                          child: const Text('Yönet'),
                        ),
                      ],
                    ),
                  ),
                ),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Stats hata: $e'),
                data: (s) => _StatsRow(stats: s),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Test bildirimi gönder'),
                    onPressed: () async {
                      final granted =
                          await NotificationService.instance.requestPermissions();
                      final perms =
                          await NotificationService.instance.checkPermissions();
                      await NotificationService.instance.showTest();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'granted=$granted alert=${perms?.isAlertEnabled} sound=${perms?.isSoundEnabled}'),
                              duration: const Duration(seconds: 6)),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _SectionTitle(label: 'KATEGORİ DOĞRULUĞU'),
              categoriesAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (cats) => _CategoryBars(categories: cats),
              ),

              const SizedBox(height: 12),
              _SectionTitle(label: 'SEZON TRENDİ'),
              trendAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (trend) => _SeasonTrendChart(trend: trend),
              ),

              const SizedBox(height: 12),
              _SectionTitle(label: 'EN ÇOK SEÇİLEN SÜRÜCÜLER'),
              driverAccAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (rows) => _DriverHits(rows: rows),
              ),

              const SizedBox(height: 12),
              _SectionTitle(label: 'ROZETLER'),
              allBadgesAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (allBadges) => myBadgesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => _Error(e),
                  data: (myBadges) {
                    final earnedSet =
                        myBadges.map((u) => u.badgeId).toSet();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: allBadges.length,
                        itemBuilder: (_, i) => _BadgeTile(
                          badge: allBadges[i],
                          earned: earnedSet.contains(allBadges[i].id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Profile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initial = profile.username.isNotEmpty
        ? profile.username[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A26), Color(0xFF0B0B12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.f1Red,
                  AppColors.f1Red.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Text(initial,
                style: tt.displayLarge?.copyWith(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          Text(profile.username,
              style: tt.headlineLarge?.copyWith(letterSpacing: 0)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProfileStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
              child:
                  _StatCard(label: 'PUAN', value: '${stats.totalScore}')),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(
                  label: 'YARIŞ', value: '${stats.racesPredicted}')),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(label: 'ROZET', value: '${stats.badgeCount}')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: tt.displayMedium
                  ?.copyWith(color: AppColors.f1Red, fontSize: 28)),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: Colors.white60, letterSpacing: 1.5, fontSize: 10)),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: AppColors.f1Red),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _Error extends StatelessWidget {
  final Object error;
  const _Error(this.error);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Hata: $error'),
      );
}

class _CategoryBars extends StatelessWidget {
  final List<CategoryAccuracy> categories;
  const _CategoryBars({required this.categories});

  String _label(String code) => switch (code) {
        'winner' => 'Kazanan',
        'podium_exact' => 'Podium (sıralı)',
        'pole' => 'Pole',
        'fastest_lap' => 'En hızlı tur',
        'dnf_exact' => 'DNF (tam)',
        'joker' => 'Joker',
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final hasData = categories.any((c) => c.total > 0);
    if (!hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Henüz puanlanmış tahmin yok.',
            style: TextStyle(color: Colors.white54)),
      );
    }
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(_label(c.category),
                        style: tt.bodySmall
                            ?.copyWith(color: Colors.white70)),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: c.rate.clamp(0, 1),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.f1Red,
                                AppColors.f1Red.withValues(alpha: 0.5),
                              ]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text('${c.correct}/${c.total}',
                        textAlign: TextAlign.right,
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white60,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeasonTrendChart extends StatelessWidget {
  final List<TrendPoint> trend;
  const _SeasonTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Sezon verisi yok.',
            style: TextStyle(color: Colors.white54)),
      );
    }
    final spots = trend
        .map((t) => FlSpot(t.round.toDouble(), t.score.toDouble()))
        .toList();
    final maxY =
        (trend.map((t) => t.score).fold<int>(0, (a, b) => a > b ? a : b)) + 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white12,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 4,
                getTitlesWidget: (v, _) => Text('R${v.toInt()}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.f1Red,
              isCurved: true,
              curveSmoothness: 0.25,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.f1Red,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.f1Red.withValues(alpha: 0.3),
                    AppColors.f1Red.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6E6E80);
  final s = hex.replaceAll('#', '');
  final v = int.tryParse(s, radix: 16);
  if (v == null) return const Color(0xFF6E6E80);
  return s.length == 6 ? Color(0xFFFF000000 | v) : Color(v);
}

class _DriverHits extends StatelessWidget {
  final List<DriverAccuracy> rows;
  const _DriverHits({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Henüz tahmin yok.',
            style: TextStyle(color: Colors.white54)),
      );
    }
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final d in rows)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    color: _parseHex(d.color),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    child: Text(d.code,
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0)),
                  ),
                  Expanded(
                    child: Text(d.fullName,
                        style: tt.bodySmall
                            ?.copyWith(color: Colors.white70),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${d.correct}/${d.predicted}',
                      style: tt.labelLarge?.copyWith(
                          color: AppColors.f1Red,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ])),
                  const SizedBox(width: 4),
                  Text('${(d.rate * 100).toStringAsFixed(0)}%',
                      style: tt.labelSmall?.copyWith(
                          color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;
  final bool earned;
  const _BadgeTile({required this.badge, required this.earned});

  Color _rarityColor() => switch (badge.rarity) {
        'legendary' => const Color(0xFFFFD700),
        'epic' => const Color(0xFFB45CFF),
        'rare' => const Color(0xFF40A9FF),
        _ => const Color(0xFF8E8E99),
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rarity = _rarityColor();
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: earned
              ? rarity.withValues(alpha: 0.12)
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned ? rarity : Colors.white12,
            width: earned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: earned ? 1.0 : 0.3,
              child: Text(badge.icon,
                  style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 4),
            Text(badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: earned ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }
}
