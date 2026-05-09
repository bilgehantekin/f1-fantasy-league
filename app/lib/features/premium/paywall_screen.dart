import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/legal_links.dart';
import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_state.dart';
import 'premium_service.dart' as premium;

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(premium.isPremiumEnabledProvider);
    final products = ref.watch(premium.premiumProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: !enabled
          ? AppEmptyState(
              icon: Icons.lock_outline,
              title: l.premiumUnavailableTitle,
              message: l.premiumUnavailableBody,
            )
          : products.when(
              loading: () => AppLoadingState(label: l.settingsLoading),
              error: (e, _) => AppErrorState(message: l.premiumUnavailableBody),
              data: (data) => _Body(
                products: data,
                busy: _busy,
                onPurchase: (product) async {
                  setState(() => _busy = true);
                  final result = await ref
                      .read(premium.premiumServiceProvider)
                      .purchase(product);
                  if (mounted) setState(() => _busy = false);
                  _showResult(result, successMessage: l.purchaseCompleted);
                },
                onRestore: () async {
                  setState(() => _busy = true);
                  final result = await ref
                      .read(premium.premiumServiceProvider)
                      .restorePurchases();
                  if (mounted) setState(() => _busy = false);
                  _showResult(result, successMessage: l.restoreCompleted);
                },
              ),
            ),
    );
  }

  void _showResult(
    premium.PurchaseResult result, {
    required String successMessage,
  }) {
    if (!mounted || result.canceled) return;
    final l = AppLocalizations.of(context);
    ref.invalidate(premium.currentUserPremiumProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.purchased ? successMessage : l.purchaseFailed),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final premium.PremiumProducts products;
  final bool busy;
  final ValueChanged<StoreProduct> onPurchase;
  final VoidCallback onRestore;

  const _Body({
    required this.products,
    required this.busy,
    required this.onPurchase,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _PaywallHero(onRestore: busy ? null : onRestore),
        const SizedBox(height: 8),
        _SectionTitle(label: l.paywallBenefitsTitle),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceHi),
          ),
          child: Column(
            children: [
              _Feature(
                label: l.paywallFeatureLeagueLimit,
                description: l.paywallFeatureLeagueLimitBody,
                icon: Icons.groups_2_outlined,
              ),
              const Divider(height: 1, color: AppColors.surfaceHi),
              _Feature(
                label: l.paywallFeatureDetailedStats,
                description: l.paywallFeatureDetailedStatsBody,
                icon: Icons.query_stats,
              ),
              const Divider(height: 1, color: AppColors.surfaceHi),
              _Feature(
                label: l.paywallFeatureFavorites,
                description: l.paywallFeatureFavoritesBody,
                icon: Icons.star_border,
              ),
              const Divider(height: 1, color: AppColors.surfaceHi),
              _Feature(
                label: l.paywallFeatureBadge,
                description: l.paywallFeatureBadgeBody,
                icon: Icons.workspace_premium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(label: l.paywallChoosePlan),
        if (!products.available) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState(
              icon: Icons.storefront_outlined,
              title: l.premiumUnavailableTitle,
              message: l.premiumUnavailableBody,
            ),
          ),
          const SizedBox(height: 12),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _PlanButton(
                  label: l.annualPlan,
                  price: products.annual!.priceString,
                  badge: l.saveWithAnnual,
                  busy: busy,
                  onPressed: () => onPurchase(products.annual!),
                ),
                const SizedBox(height: 10),
                _PlanButton(
                  label: l.monthlyPlan,
                  price: products.monthly!.priceString,
                  busy: busy,
                  onPressed: () => onPurchase(products.monthly!),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            TextButton(
              onPressed: () async => openExternalLink(LegalLinks.terms),
              child: Text(l.terms),
            ),
            TextButton(
              onPressed: () async => openExternalLink(LegalLinks.privacy),
              child: Text(l.privacy),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PaywallHero extends StatelessWidget {
  final VoidCallback? onRestore;

  const _PaywallHero({required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            const Color(0xFFFFD166).withValues(alpha: 0.2),
            AppColors.f1Red.withValues(alpha: 0.08),
            AppColors.carbon,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l.cancel,
                  onPressed: () => safeBack(context),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onRestore,
                  child: Text(l.restorePurchases),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE08A),
                  Color(0xFFFFD166),
                  Color(0xFFF2A900),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFF1A1208),
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFFFD166).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFFFFD166).withValues(alpha: 0.34),
              ),
            ),
            child: Text(
              l.premiumMember.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                color: Color(0xFFFFD166),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.paywallHeroTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              l.paywallHeroBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.42,
                color: Colors.white.withValues(alpha: 0.64),
              ),
            ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;

  const _Feature({
    required this.label,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFFFD166).withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: const Color(0xFFFFD166), size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlanButton extends StatelessWidget {
  final String label;
  final String price;
  final String? badge;
  final bool busy;
  final VoidCallback onPressed;

  const _PlanButton({
    required this.label,
    required this.price,
    this.badge,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selected = badge != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFFD166),
                      Color(0xFFF2A900),
                      AppColors.f1Red,
                    ],
                  )
                : null,
            color: selected ? null : AppColors.surfaceHi,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B1610) : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? const Color(0xFFFFD166)
                      : Colors.white.withValues(alpha: 0.34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD166),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1208),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected
                            ? AppLocalizations.of(context).annualPlanBody
                            : AppLocalizations.of(context).monthlyPlanBody,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  price,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? const Color(0xFFFFD166) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
