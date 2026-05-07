import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/legal_links.dart';
import '../../core/navigation.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_state.dart';
import '../league/league_controller.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final myBadgesAsync = ref.watch(myBadgesProvider);
    final allBadgesAsync = ref.watch(allBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          tooltip: 'Geri',
          onPressed: () => safeBack(context),
        ),
        title: const Text(
          'PROFİL',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: 'Bildirim ayarları',
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: profileAsync.when(
        loading: () => const AppLoadingState(label: 'Profil yükleniyor'),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () {
            ref.invalidate(profileProvider);
            ref.invalidate(profileStatsProvider);
            ref.invalidate(myBadgesProvider);
          },
        ),
        data: (p) {
          if (p == null) {
            return const AppEmptyState(
              icon: Icons.login_outlined,
              title: 'Giriş gerekli',
              message: 'Profilini görmek için hesabına giriş yapmalısın.',
            );
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A26), Color(0xFF15151E)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1F1F2E), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    _HeroProfile(profile: p),
                    statsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) =>
                          Text('İstatistik hatası: ${friendlyError(e)}'),
                      data: (s) {
                        final leaguesAsync = ref.watch(myLeaguesProvider);
                        final bestRank = leaguesAsync.maybeWhen(
                          data: _bestLeagueRank,
                          orElse: () => null,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _StatsCards(stats: s, bestRank: bestRank),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(label: 'ROZETLER'),
              myBadgesAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (myBadges) {
                  return allBadgesAsync.when(
                    loading: () => const _Loading(),
                    error: (e, _) => _Error(e),
                    data: (allBadges) => _BadgesCarousel(
                      allBadges: allBadges,
                      myBadges: myBadges,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle(label: 'SEZON İSTATİSTİKLERİ'),
              statsAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _Error(e),
                data: (s) => _SeasonStats(stats: s),
              ),
              const SizedBox(height: 24),
              _SectionTitle(label: 'LİGLER'),
              const _LeaguesList(),
              const SizedBox(height: 24),
              _SectionTitle(label: 'HESAP VE YASAL'),
              const _AccountLifecyclePanel(),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => supabase.auth.signOut(),
                  child: const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF2D55),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _AccountLifecyclePanel extends StatelessWidget {
  const _AccountLifecyclePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.info_outline,
            title: 'Hakkında',
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1, color: Color(0xFF1F1F2E)),
          _AccountRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            onTap: () => _openLegal(context, LegalLinks.privacy),
          ),
          const Divider(height: 1, color: Color(0xFF1F1F2E)),
          _AccountRow(
            icon: Icons.description_outlined,
            title: 'Kullanım Şartları',
            onTap: () => _openLegal(context, LegalLinks.terms),
          ),
          const Divider(height: 1, color: Color(0xFF1F1F2E)),
          _AccountRow(
            icon: Icons.delete_outline,
            title: 'Hesabı silme talebi oluştur',
            destructive: true,
            onTap: () => _confirmDeletionRequest(context),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool destructive;
  final VoidCallback onTap;

  const _AccountRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF2D55) : Colors.white;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color.withValues(alpha: 0.9), size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

Future<void> _showAboutDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A26),
      title: const Text('GridCall hakkında'),
      content: const SingleChildScrollView(
        child: Text(
          'GridCall, Formula 1\'i takip eden hayranlar için bağımsız bir tahmin '
          'uygulamasıdır.\n\n'
          'GridCall; Formula 1, FIA, Formula One Management, takımlar, sürücüler '
          'veya sponsorlarla bağlantılı, onlar tarafından desteklenen ya da onaylanan '
          'bir uygulama değildir. F1 ile ilgili tüm marka, logo ve isimler ilgili '
          'sahiplerinin tescilli markalarıdır ve burada yalnızca bilgilendirme '
          'amacıyla kullanılır.\n\n'
          'Yarış zamanlama ve sonuç verileri, kamuya açık üçüncü taraf bir kaynak '
          'olan OpenF1 üzerinden alınır. OpenF1 da resmi bir kaynak değildir.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}

Future<void> _openLegal(BuildContext context, Uri uri) async {
  try {
    await openExternalLink(uri);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
  }
}

Future<void> _confirmDeletionRequest(BuildContext context) async {
  final reasonCtrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hesabını sil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talep oluşturduğun andan itibaren 30 gün içinde hesabın ve sana ait '
            'tüm tahminler, lig üyelikleri, rozetler ve profil bilgileri kalıcı '
            'olarak silinecek. Bu süre içinde fikrini değiştirirsen '
            'bilgehan.2002@gmail.com adresine yazarak iptal talep edebilirsin.\n\n'
            'Talep oluşturulduktan sonra oturumun kapatılır ve hesabın diğer '
            'kullanıcılara görünmez olur.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'Silme sebebini yazabilirsin',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF2D55),
          ),
          child: const Text('Talep Oluştur'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    reasonCtrl.dispose();
    return;
  }

  try {
    final result = await requestAccountDeletion(reason: reasonCtrl.text.trim());
    reasonCtrl.dispose();
    if (!context.mounted) return;
    final scheduledMessage = result.scheduledFor != null
        ? 'Hesabın ${_formatDate(result.scheduledFor!)} tarihinde silinecek.'
        : 'Hesap silme talebin alındı.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$scheduledMessage Çıkış yapılıyor…'),
        backgroundColor: AppColors.lockGreen,
        duration: const Duration(seconds: 3),
      ),
    );
    // Kullanıcı silinmiş hesapla devam etmesin diye oturumu kapat;
    // router auth state değişimini görüp /auth'a yönlendirecek.
    await supabase.auth.signOut();
  } catch (e) {
    reasonCtrl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Talep oluşturulamadı: ${friendlyError(e)}'),
        backgroundColor: AppColors.liveRed,
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd.$mm.${local.year}';
}

class _HeroProfile extends StatelessWidget {
  final Profile profile;
  const _HeroProfile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = profile.username.isNotEmpty
        ? profile.username[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE10600),
            ),
            child: Text(
              initial,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          // Stats grid would go here but we'll use _StatsCards separately
        ],
      ),
    );
  }
}

_BestRankInfo? _bestLeagueRank(List<League> leagues) {
  _BestRankInfo? best;
  for (final league in leagues) {
    final rank = league.myRank;
    if (rank == null) continue;
    if (best == null || rank < best.rank) {
      best = _BestRankInfo(rank: rank, leagueName: league.name);
    }
  }
  return best;
}

class _BestRankInfo {
  final int rank;
  final String leagueName;
  const _BestRankInfo({required this.rank, required this.leagueName});
}

class _StatsCards extends StatelessWidget {
  final ProfileStats stats;
  final _BestRankInfo? bestRank;
  const _StatsCards({required this.stats, this.bestRank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StatCard(
              label: 'Toplam Puan',
              value: '${stats.totalScore}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'En İyi Sıra',
              value: bestRank == null ? '-' : '#${bestRank!.rank}',
              subtitle: bestRank?.leagueName,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Haftalık Rekor',
              value: '${stats.bestScore}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  const _StatCard({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE10600),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
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
              color: const Color(0xFFE10600),
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

class _BadgesCarousel extends StatefulWidget {
  final List<AppBadge> allBadges;
  final List<UserBadge> myBadges;

  const _BadgesCarousel({required this.allBadges, required this.myBadges});

  @override
  State<_BadgesCarousel> createState() => _BadgesCarouselState();
}

class _BadgesCarouselState extends State<_BadgesCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges = widget.myBadges
        .map((userBadge) => userBadge.badge)
        .whereType<AppBadge>()
        .toList();
    final earnedBadgeIds = earnedBadges.map((badge) => badge.id).toSet();
    final badges = [
      ...earnedBadges,
      ...widget.allBadges.where((badge) => !earnedBadgeIds.contains(badge.id)),
    ];
    final pages = <List<AppBadge>>[
      for (var i = 0; i < badges.length; i += 3)
        badges.sublist(i, (i + 3).clamp(0, badges.length)),
    ];

    if (badges.isEmpty) {
      return const AppEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Henüz rozet yok',
        message:
            'Yarış sonuçları geldikçe başarılarına göre rozet kazanacaksın.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - (horizontalPadding * 2) - (gap * 2)) / 3;
        final cardHeight = (cardWidth * 1.08).clamp(118.0, 160.0);

        return SizedBox(
          height: cardHeight + 24,
          child: Column(
            children: [
              SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, pageIndex) {
                    final pageBadges = pages[pageIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: gap),
                            SizedBox(
                              width: cardWidth,
                              child: i < pageBadges.length
                                  ? _BadgeTile(
                                      badge: pageBadges[i],
                                      isEarned: earnedBadgeIds.contains(
                                        pageBadges[i].id,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (pages.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == _page ? 14 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? const Color(0xFFE10600)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;
  final bool isEarned;

  const _BadgeTile({required this.badge, this.isEarned = true});

  @override
  Widget build(BuildContext context) {
    final display = _BadgeDisplay.fromBadge(badge);

    return Opacity(
      opacity: isEarned ? 1 : 0.42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A26),
          borderRadius: BorderRadius.circular(8),
          border: isEarned
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Flexible(
              child: Center(
                child: Text(
                  display.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (display.category != null) ...[
              const SizedBox(height: 3),
              Text(
                display.category!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.52),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeDisplay {
  final String name;
  final String? category;

  const _BadgeDisplay({required this.name, this.category});

  factory _BadgeDisplay.fromBadge(AppBadge badge) {
    const namesByBaseCode = {
      'bullseye_podium': 'Podyum Tam İsabet',
      'pole_caller': 'Pole Avcısı',
      'dnf_oracle': 'DNF Kahini',
      'weekly_winner': 'Hafta Şampiyonu',
      'perfect_week': 'Mükemmel Hafta',
      'three_in_row': 'Üçlü Seri',
    };

    final isSprint = badge.code.startsWith('sprint_');
    final baseCode = isSprint
        ? badge.code.substring('sprint_'.length)
        : badge.code;
    final sharedName = namesByBaseCode[baseCode];

    if (sharedName == null) return _BadgeDisplay(name: badge.name);

    return _BadgeDisplay(
      name: sharedName,
      category: isSprint ? 'Sprint' : 'Ana Yarış',
    );
  }
}

class _SeasonStats extends StatelessWidget {
  final ProfileStats stats;
  const _SeasonStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bestEvent = stats.bestEventName == null
        ? '-'
        : stats.bestEventMode == 'sprint'
        ? '${stats.bestEventName} — Sprint'
        : stats.bestEventName!;
    final rows = [
      ('Ana yarış ortalama puanı', stats.mainAverageScore.toStringAsFixed(1)),
      (
        'Sprint yarışı ortalama puanı',
        stats.sprintAverageScore.toStringAsFixed(1),
      ),
      ('Ortalama hafta puanı', stats.weeklyAverageScore.toStringAsFixed(1)),
      ('Katıldığı hafta', '${stats.weeksParticipated}'),
      ('En iyi GP', bestEvent),
      ('Aktif seri', '${stats.activeStreak} hafta'),
      (
        'En iyi lig',
        stats.bestLeagueName == null
            ? '-'
            : '${stats.bestLeagueName} (${stats.bestLeagueScore})',
      ),
      ('Rozet', '${stats.badgeCount}'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Sezon boyunca yaptığın tahminlerin ortalama performansı, katılım düzenin, en iyi yarış haftan ve liglerdeki durumun burada özetlenir.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${rows[i].$1}:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (stats.leaguePerformances.isNotEmpty) ...[
            const Divider(height: 28, color: Color(0xFF1F1F2E)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LİG BAZLI PERFORMANS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final league in stats.leaguePerformances)
              _LeaguePerformanceRow(league: league),
          ],
        ],
      ),
    );
  }
}

class _LeaguePerformanceRow extends StatelessWidget {
  final LeaguePerformance league;

  const _LeaguePerformanceRow({required this.league});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${league.rank}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE10600),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  league.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yarış ${league.mainScore} · Sprint ${league.sprintScore}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${league.totalScore}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE10600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaguesList extends StatelessWidget {
  const _LeaguesList();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final leaguesAsync = ref.watch(myLeaguesProvider);
        return leaguesAsync.when(
          loading: () => const _Loading(),
          error: (e, _) => _Error(e),
          data: (leagues) {
            if (leagues.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Henüz bir lige katılmadın.',
                  style: TextStyle(color: Color(0x99FFFFFF)),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final league in leagues)
                    InkWell(
                      onTap: () => context.push('/leagues/${league.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    league.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Davet kodu: ${league.inviteCode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${league.memberCount ?? 0} üye',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '#${league.myRank ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE10600),
                                  ),
                                ),
                                Text(
                                  'SIRALAMA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const AppLoadingState(label: 'Bölüm yükleniyor');
}

class _Error extends StatelessWidget {
  final Object error;
  const _Error(this.error);
  @override
  Widget build(BuildContext context) =>
      AppErrorState(message: friendlyError(error));
}
