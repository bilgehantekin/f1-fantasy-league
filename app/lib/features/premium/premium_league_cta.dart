import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import 'premium_theme.dart';

class PremiumLeagueCta extends StatelessWidget {
  const PremiumLeagueCta({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: PremiumColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumColors.goldBorder(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PremiumColors.goldFill(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PremiumColors.goldBorder(0.25)),
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 20,
              color: PremiumColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.premiumLeagues, style: PremiumTextStyles.eyebrow),
                const SizedBox(height: 2),
                Text(
                  l.premiumUpsellLeaguesTitle,
                  style: const TextStyle(
                    fontFamily: PremiumTextStyles.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.premiumUpsellLeaguesBody,
                  style: const TextStyle(
                    fontFamily: PremiumTextStyles.family,
                    fontSize: 12,
                    color: Color(0x99FFFFFF),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () => context.push('/premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.gold,
                foregroundColor: PremiumColors.goldOnText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l.upgradeShort.toUpperCase(),
                style: const TextStyle(
                  fontFamily: PremiumTextStyles.family,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
