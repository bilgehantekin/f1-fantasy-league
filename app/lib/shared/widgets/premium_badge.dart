import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class PremiumBadge extends StatelessWidget {
  final bool compact;

  const PremiumBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).premiumBadge;
    return Tooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD166).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFFD166).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond_rounded,
              size: compact ? 13 : 15,
              color: const Color(0xFFFFD166),
            ),
            if (!compact) ...[
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context).premium,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD166),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
