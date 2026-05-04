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
                      error: (e, _) => Text('Stats hata: ${friendlyError(e)}'),
                      data: (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _StatsCards(stats: s),
                      ),
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
                  final earnedBadges = myBadges
                      .where((userBadge) => userBadge.badge != null)
                      .toList();
                  if (earnedBadges.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Henüz rozet yok',
                      message:
                          'Yarış sonuçları geldikçe başarılarına göre rozet kazanacaksın.',
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: earnedBadges.length,
                      itemBuilder: (_, i) =>
                          _BadgeTile(badge: earnedBadges[i].badge!),
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
              // Premium upsell şimdilik gizli — ileride tekrar açılacak.
              // if (!isPremium) _PremiumUpsell(),
              // const SizedBox(height: 24),
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
      title: const Text('Hesap silme talebi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talep oluşturduğunda hesabın ve verilerin silinmesi için işlem başlatılır. Bu işlem geri alınamayabilir.',
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
    await requestAccountDeletion(reason: reasonCtrl.text.trim());
    reasonCtrl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hesap silme talebin alındı. Çıkış yapılıyor…'),
        backgroundColor: AppColors.lockGreen,
        duration: Duration(seconds: 2),
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
          const SizedBox(height: 4),
          Text(
            profile.isPremium ? 'Premium üye' : 'Free üye',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Stats grid would go here but we'll use _StatsCards separately
        ],
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final ProfileStats stats;
  const _StatsCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(label: 'Genel Puan', value: '${stats.totalScore}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'En Yüksek Skor',
              value: '${stats.bestScore}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Skorlanan Etkinlik',
              value: '${stats.eventsPredicted}',
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
  const _StatCard({required this.label, required this.value});

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

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonStats extends StatelessWidget {
  final ProfileStats stats;
  const _SeasonStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Ana yarış skoru', '${stats.mainScore}'),
      ('Sprint skoru', '${stats.sprintScore}'),
      ('Ortalama puan', stats.averageScore.toStringAsFixed(1)),
      ('En iyi skor', '${stats.bestScore}'),
      ('Ana yarış tahmini', '${stats.mainEventsPredicted}'),
      ('Sprint tahmini', '${stats.sprintEventsPredicted}'),
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
            'Genel puan, aynı etkinlik için farklı liglerdeki en iyi skor üzerinden hesaplanır. Lig performansı ise lig bazlı toplamı gösterir.',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${rows[i].$1}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

// ignore: unused_element
class _PremiumUpsell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE10600), Color(0xFFA00500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, size: 24),
              SizedBox(width: 8),
              Text(
                'PREMİUM\'A GEÇ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UpsellItem(text: 'Gelişmiş istatistikler'),
          const SizedBox(height: 8),
          _UpsellItem(text: 'Sınırsız lig katılımı'),
          const SizedBox(height: 8),
          _UpsellItem(text: 'Özel rozetler'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE10600),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'HEMEN BAŞLA',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpsellItem extends StatelessWidget {
  final String text;
  const _UpsellItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
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
