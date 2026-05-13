import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/env.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_state.dart';
import 'league_controller.dart';
import '../premium/premium_league_cta.dart';
import '../premium/premium_service.dart';

class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
  @override
  Widget build(BuildContext context) {
    final leagues = ref.watch(myLeaguesProvider);
    final tt = Theme.of(context).textTheme;
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
        title: Text(
          l.myLeagues,
          style: tt.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F2E)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          _SectionTitle(label: l.activeLeagues),
          const SizedBox(height: 12),
          if (Env.enablePremium && !isPremium) ...[
            const PremiumLeagueCta(),
            const SizedBox(height: 16),
          ],
          leagues.when(
            loading: () => AppLoadingState(label: l.leaguesLoading),
            error: (e, _) => AppErrorState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(myLeaguesProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return AppEmptyState(
                  icon: Icons.groups_outlined,
                  title: l.noLeagueYet,
                  message: l.noLeagueYetMessage,
                );
              }
              return Column(
                children: list.map((league) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/leagues/${league.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                league.name,
                                                style: tt.titleMedium?.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (league.isFavorite) ...[
                                              const Icon(
                                                Icons.star,
                                                size: 15,
                                                color: Color(0xFFFFD166),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            const Icon(
                                              Icons.lock_outline,
                                              size: 14,
                                              color: Color(0x66FFFFFF),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.people,
                                              size: 12,
                                              color: Color(0x99FFFFFF),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l.membersCount(
                                                league.memberCount ?? 0,
                                              ),
                                              style: tt.bodySmall?.copyWith(
                                                fontSize: 12,
                                                color: const Color(0x99FFFFFF),
                                              ),
                                            ),
                                          ],
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFE10600),
                                        ),
                                      ),
                                      Text(
                                        l.standing,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: const Color(0xFF15151E),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.viewDetails,
                                    style: tt.bodySmall?.copyWith(
                                      fontSize: 14,
                                      color: const Color(0x99FFFFFF),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Color(0x66FFFFFF),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
