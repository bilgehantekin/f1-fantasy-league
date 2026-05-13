import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/legal_links.dart';
import '../../core/navigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_state.dart';
import '../league/league_controller.dart';
import '../profile/profile_controller.dart';
import 'premium_service.dart' as premium;
import 'premium_theme.dart';

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
    final offering = ref.watch(premium.premiumOfferingProvider);

    return Scaffold(
      backgroundColor: PremiumColors.carbon,
      body: !enabled
          ? AppEmptyState(
              icon: Icons.lock_outline,
              title: l.premiumUnavailableTitle,
              message: l.premiumUnavailableBody,
            )
          : offering.when(
              loading: () => AppLoadingState(label: l.settingsLoading),
              error: (e, _) => AppErrorState(message: l.premiumUnavailableBody),
              data: (data) => _Body(
                offering: data,
                busy: _busy,
                onPurchase: (package) async {
                  setState(() => _busy = true);
                  final result = await ref
                      .read(premium.premiumServiceProvider)
                      .purchasePackage(package);
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
    if (result.purchased) {
      ref.invalidate(premium.currentUserPremiumProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(myLeaguesProvider);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.purchased ? successMessage : l.purchaseFailed),
      ),
    );
    if (result.purchased) safeBack(context);
  }
}

class _Body extends StatefulWidget {
  final premium.PremiumOffering offering;
  final bool busy;
  final ValueChanged<Package> onPurchase;
  final VoidCallback onRestore;

  const _Body({
    required this.offering,
    required this.busy,
    required this.onPurchase,
    required this.onRestore,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Package? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.offering.annual ?? widget.offering.monthly;
  }

  @override
  void didUpdateWidget(covariant _Body old) {
    super.didUpdateWidget(old);
    _selected ??= widget.offering.annual ?? widget.offering.monthly;
  }

  bool get _selectedIsAnnual =>
      _selected != null && _selected == widget.offering.annual;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final available = widget.offering.available;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Hero(
            onClose: () => safeBack(context),
            onRestore: widget.busy ? null : widget.onRestore,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FeaturesCard(),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionTitle(label: l.paywallChoosePlan),
          ),
          if (!available)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppEmptyState(
                icon: Icons.storefront_outlined,
                title: l.premiumUnavailableTitle,
                message: l.premiumUnavailableBody,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (widget.offering.annual != null) ...[
                    _PlanCard(
                      title: l.annualPlan,
                      sub: _annualMonthlyEquivalent(
                        context,
                        widget.offering.annual!.storeProduct,
                      ),
                      price: widget.offering.annual!.storeProduct.priceString,
                      unit: l.paywallPerYear,
                      badge: l.paywallBestValueShort,
                      selected: _selected == widget.offering.annual,
                      onTap: () => setState(
                        () => _selected = widget.offering.annual,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.offering.monthly != null)
                    _PlanCard(
                      title: l.monthlyPlan,
                      sub: l.paywallMonthlyCancelAnytime,
                      price: widget.offering.monthly!.storeProduct.priceString,
                      unit: l.paywallPerMonth,
                      selected: _selected == widget.offering.monthly,
                      onTap: () => setState(
                        () => _selected = widget.offering.monthly,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _CtaButton(
            label: l.paywallStartMembership(
              _selectedIsAnnual ? l.annualPlan : l.monthlyPlan,
            ),
            enabled: available && _selected != null && !widget.busy,
            busy: widget.busy,
            onTap: () {
              final pkg = _selected;
              if (pkg != null) widget.onPurchase(pkg);
            },
          ),
          const SizedBox(height: 8),
          _Footer(),
          SizedBox(height: 6 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

String _annualMonthlyEquivalent(BuildContext context, StoreProduct product) {
  final l = AppLocalizations.of(context);
  final perMonth = product.price / 12.0;
  final locale = Localizations.localeOf(context);
  final formatLocale = locale.languageCode == 'tr' ? 'tr_TR' : 'en_US';
  final formatter = NumberFormat.simpleCurrency(
    locale: formatLocale,
    name: product.currencyCode,
  );
  return l.paywallPerMonthLong(formatter.format(perMonth));
}

// ─── Hero ─────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onRestore;

  const _Hero({required this.onClose, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0x1AC9A24A), PremiumColors.carbon],
          stops: [0.0, 0.7],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xB3FFFFFF),
                      size: 22,
                    ),
                    onPressed: onClose,
                  ),
                  TextButton(
                    onPressed: onRestore,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Color(0x26FFFFFF)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l.restorePurchases.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            decoration: BoxDecoration(
              color: PremiumColors.goldFill(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PremiumColors.goldBorder(0.33)),
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 30,
              color: PremiumColors.gold,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'GRIDCALL '),
                TextSpan(
                  text: l.paywallBrandPremium,
                  style: const TextStyle(color: PremiumColors.gold),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.paywallHeroTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xCCFFFFFF),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: PremiumColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Features ─────────────────────────────────────────────────

class _FeaturesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final features = <_FeatureData>[
      _FeatureData(
        icon: Icons.groups_outlined,
        title: l.paywallFeatureLeagueLimit,
        subtitle: l.paywallFeatureLeagueLimitBody,
      ),
      _FeatureData(
        icon: Icons.show_chart,
        title: l.paywallFeatureDetailedStats,
        subtitle: l.paywallFeatureDetailedStatsBody,
      ),
      _FeatureData(
        icon: Icons.star_outline,
        title: l.paywallFeatureFavorites,
        subtitle: l.paywallFeatureFavoritesBody,
      ),
      _FeatureData(
        icon: Icons.shield_outlined,
        title: l.paywallFeatureBadge,
        subtitle: l.paywallFeatureBadgeBody,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionTitle(label: l.paywallBenefitsTitle),
        Container(
          decoration: BoxDecoration(
            color: PremiumColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PremiumColors.surfaceHi),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < features.length; i++) ...[
                _FeatureRow(data: features[i]),
                if (i < features.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: PremiumColors.surfaceHi,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureRow extends StatelessWidget {
  final _FeatureData data;
  const _FeatureRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: PremiumColors.goldFill(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PremiumColors.goldBorder(0.20)),
            ),
            child: Icon(data.icon, size: 16, color: PremiumColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 11,
                    color: Color(0x94FFFFFF),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String price;
  final String unit;
  final String sub;
  final String? badge;

  const _PlanCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.price,
    required this.unit,
    required this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: PremiumColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? PremiumColors.gold : PremiumColors.surfaceHi,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            _Radio(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'TitilliumWeb',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: PremiumColors.goldFill(0.14),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: PremiumColors.goldBorder(0.33),
                            ),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontFamily: 'TitilliumWeb',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: PremiumColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'TitilliumWeb',
                      fontSize: 11,
                      color: Color(0x8CFFFFFF),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? PremiumColors.gold : Colors.white,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0x80FFFFFF),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? PremiumColors.goldFill(0.12) : Colors.transparent,
        border: Border.all(
          color: selected
              ? PremiumColors.gold
              : Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PremiumColors.gold,
                ),
              ),
            )
          : null,
    );
  }
}

// ─── CTA ──────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: PremiumColors.gold,
            foregroundColor: PremiumColors.goldOnText,
            disabledBackgroundColor: PremiumColors.surfaceHi,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: PremiumColors.goldOnText,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: 16,
                      color: enabled
                          ? PremiumColors.goldOnText
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'TitilliumWeb',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            l.paywallFooterDisclaimer,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 10.5,
              color: Color(0x80FFFFFF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async => openExternalLink(LegalLinks.terms),
                child: Text(
                  l.terms,
                  style: const TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 11,
                    color: Color(0x8CFFFFFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                ' · ',
                style: TextStyle(fontSize: 11, color: Color(0x8CFFFFFF)),
              ),
              GestureDetector(
                onTap: () async => openExternalLink(LegalLinks.privacy),
                child: Text(
                  l.privacy,
                  style: const TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 11,
                    color: Color(0x8CFFFFFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
