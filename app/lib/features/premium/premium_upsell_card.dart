import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import 'premium_theme.dart';

class PremiumUpsellCard extends StatelessWidget {
  const PremiumUpsellCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PremiumColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumColors.goldBorder(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PremiumColors.goldFill(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PremiumColors.goldBorder(0.25)),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 18,
                    color: PremiumColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Text(l.gridcallPremium, style: PremiumTextStyles.eyebrow),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.premiumUpsellProfileTitle, style: PremiumTextStyles.title),
            const SizedBox(height: 6),
            Text(l.premiumUpsellProfileBody, style: PremiumTextStyles.body),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.push('/premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumColors.gold,
                  foregroundColor: PremiumColors.goldOnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  l.upgradeToPremium.toUpperCase(),
                  style: PremiumTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
