import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_state.dart';
import 'league_controller.dart';

class LeagueSettingsScreen extends ConsumerWidget {
  final String leagueId;

  const LeagueSettingsScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueProvider(leagueId));
    final membersAsync = ref.watch(leagueMembersProvider(leagueId));
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: Text(l.leagueSettings)),
      body: leagueAsync.when(
        loading: () => AppLoadingState(label: l.leagueSettingsLoading),
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
                    _SectionTitle(label: l.general),
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
                      l.inviteCodeValue(league.inviteCode),
                      style: const TextStyle(color: Color(0x99FFFFFF)),
                    ),
                    const SizedBox(height: 16),
                    if (isOwner) ...[
                      FilledButton.icon(
                        onPressed: () => _rename(context, ref, league.name),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.changeLeagueName),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _regenerateCode(context, ref),
                        icon: const Icon(Icons.refresh),
                        label: Text(l.refreshInviteCode),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _delete(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.deleteLeague),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.liveRed,
                        ),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: () => _leave(context, ref),
                        icon: const Icon(Icons.logout),
                        label: Text(l.leaveLeague),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.liveRed,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(label: l.members),
              const SizedBox(height: 12),
              membersAsync.when(
                loading: () => AppLoadingState(label: l.membersLoading),
                error: (e, _) => AppErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.invalidate(leagueMembersProvider(leagueId)),
                ),
                data: (members) {
                  // Sort: owner first, current user second (if not owner),
                  // others after.
                  final sorted = [...members]..sort((a, b) {
                    int weight(LeagueMember m) {
                      if (m.role == 'owner') return 0;
                      if (m.userId == currentUserId) return 1;
                      return 2;
                    }
                    final w = weight(a).compareTo(weight(b));
                    if (w != 0) return w;
                    return a.username
                        .toLowerCase()
                        .compareTo(b.username.toLowerCase());
                  });
                  return Column(
                    children: [
                      for (final member in sorted)
                        _MemberTile(
                          member: member,
                          isOwner: isOwner,
                          isSelf: member.userId == currentUserId,
                          onRemove: () => _removeMember(context, ref, member),
                          onTransfer: () =>
                              _transferOwnership(context, ref, member),
                        ),
                    ],
                  );
                },
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
        title: Text(AppLocalizations.of(context).leagueName),
        content: TextField(
          controller: ctrl,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).newLeagueName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).save),
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
      AppLocalizations.of(context).refreshInviteCodeQuestion,
      AppLocalizations.of(context).refreshInviteCodeBody,
    );
    if (!ok) return;
    await regenerateLeagueInviteCode(leagueId);
    ref.invalidate(leagueProvider(leagueId));
    ref.invalidate(myLeaguesProvider);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      AppLocalizations.of(context).leaveLeagueQuestion,
      AppLocalizations.of(context).leaveLeagueBody,
    );
    if (!ok) return;
    await leaveLeague(leagueId);
    ref.invalidate(myLeaguesProvider);
    ref.invalidate(seasonStandingsProvider(leagueId));
    ref.invalidate(leagueMembersProvider(leagueId));
    if (context.mounted) context.go('/calendar');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      AppLocalizations.of(context).deleteLeagueQuestion,
      AppLocalizations.of(context).deleteLeagueBody,
    );
    if (!ok) return;
    try {
      await deleteLeague(leagueId);
      ref.invalidate(myLeaguesProvider);
      ref.invalidate(leagueMembersProvider(leagueId));
      if (context.mounted) context.go('/calendar');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    LeagueMember member,
  ) async {
    final ok = await _confirm(
      context,
      AppLocalizations.of(context).removeMemberQuestion(member.username),
      AppLocalizations.of(context).removeMemberBody,
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
      AppLocalizations.of(context).transferOwnershipQuestion,
      AppLocalizations.of(context).transferOwnershipBody(member.username),
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
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).continueAction),
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

  String _localizedRole(BuildContext context, String role) {
    final l = AppLocalizations.of(context);
    switch (role) {
      case 'owner':
        return l.leagueRoleOwner;
      case 'member':
        return l.leagueRoleMember;
      default:
        return role.toUpperCase();
    }
  }

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).you,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: AppColors.f1Red,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _localizedRole(context, member.role),
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
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'transfer',
                  child: Text(AppLocalizations.of(context).transferOwnership),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(AppLocalizations.of(context).removeMember),
                ),
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
