import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../shared/widgets/app_state.dart';
import 'league_controller.dart';

class LeagueSettingsScreen extends ConsumerWidget {
  final String leagueId;

  const LeagueSettingsScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueProvider(leagueId));
    final membersAsync = ref.watch(leagueMembersProvider(leagueId));

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: const Text('LİG AYARLARI')),
      body: leagueAsync.when(
        loading: () => const AppLoadingState(label: 'Lig ayarları yükleniyor'),
        error: (e, _) => AppErrorState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(leagueProvider(leagueId)),
        ),
        data: (league) {
          final currentUserId = supabase.auth.currentUser?.id;
          final isOwner = league.ownerId == currentUserId;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(label: 'GENEL'),
                    const SizedBox(height: 12),
                    Text(
                      league.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Davet kodu: ${league.inviteCode}',
                      style: const TextStyle(color: Color(0x99FFFFFF)),
                    ),
                    const SizedBox(height: 16),
                    if (isOwner) ...[
                      FilledButton.icon(
                        onPressed: () => _rename(context, ref, league.name),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('LİG ADINI DEĞİŞTİR'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _regenerateCode(context, ref),
                        icon: const Icon(Icons.refresh),
                        label: const Text('DAVET KODUNU YENİLE'),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: () => _leave(context, ref),
                        icon: const Icon(Icons.logout),
                        label: const Text('LİGDEN AYRIL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.liveRed,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(label: 'ÜYELER'),
              const SizedBox(height: 12),
              membersAsync.when(
                loading: () =>
                    const AppLoadingState(label: 'Üyeler yükleniyor'),
                error: (e, _) => AppErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.invalidate(leagueMembersProvider(leagueId)),
                ),
                data: (members) => Column(
                  children: [
                    for (final member in members)
                      _MemberTile(
                        member: member,
                        isOwner: isOwner,
                        isSelf: member.userId == currentUserId,
                        onRemove: () => _removeMember(context, ref, member),
                        onTransfer: () =>
                            _transferOwnership(context, ref, member),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final ctrl = TextEditingController(text: currentName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lig adı'),
        content: TextField(
          controller: ctrl,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Yeni lig adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    await updateLeagueName(leagueId, ctrl.text.trim());
    ref.invalidate(leagueProvider(leagueId));
    ref.invalidate(myLeaguesProvider);
  }

  Future<void> _regenerateCode(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      'Davet kodu yenilensin mi?',
      'Eski davet kodu artık çalışmayacak.',
    );
    if (!ok) return;
    await regenerateLeagueInviteCode(leagueId);
    ref.invalidate(leagueProvider(leagueId));
    ref.invalidate(myLeaguesProvider);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      'Ligden ayrılmak istiyor musun?',
      'Tekrar katılmak için yeni davet koduna ihtiyacın olacak.',
    );
    if (!ok) return;
    await leaveLeague(leagueId);
    ref.invalidate(myLeaguesProvider);
    ref.invalidate(seasonStandingsProvider(leagueId));
    ref.invalidate(leagueMembersProvider(leagueId));
    if (context.mounted) context.go('/calendar');
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    LeagueMember member,
  ) async {
    final ok = await _confirm(
      context,
      '${member.username} çıkarılsın mı?',
      'Üye ligden kaldırılacak.',
    );
    if (!ok) return;
    await removeLeagueMember(leagueId, member.userId);
    ref.invalidate(leagueMembersProvider(leagueId));
    ref.invalidate(seasonStandingsProvider(leagueId));
    ref.invalidate(myLeaguesProvider);
  }

  Future<void> _transferOwnership(
    BuildContext context,
    WidgetRef ref,
    LeagueMember member,
  ) async {
    final ok = await _confirm(
      context,
      'Sahiplik devredilsin mi?',
      '${member.username} lig sahibi olacak.',
    );
    if (!ok) return;
    await transferLeagueOwnership(leagueId, member.userId);
    ref.invalidate(leagueProvider(leagueId));
    ref.invalidate(leagueMembersProvider(leagueId));
    ref.invalidate(myLeaguesProvider);
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Devam'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _MemberTile extends StatelessWidget {
  final LeagueMember member;
  final bool isOwner;
  final bool isSelf;
  final VoidCallback onRemove;
  final VoidCallback onTransfer;

  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isSelf,
    required this.onRemove,
    required this.onTransfer,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x99FFFFFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner && !isSelf && member.role != 'owner')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') onRemove();
                if (value == 'transfer') onTransfer();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'transfer',
                  child: Text('Sahipliği devret'),
                ),
                PopupMenuItem(value: 'remove', child: Text('Üyeyi çıkar')),
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      color: AppColors.f1Red,
    ),
  );
}
