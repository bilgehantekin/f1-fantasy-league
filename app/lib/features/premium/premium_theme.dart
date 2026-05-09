import 'package:flutter/material.dart';

class PremiumColors {
  PremiumColors._();

  static const carbon = Color(0xFF0B0B12);
  static const surface = Color(0xFF15151E);
  static const surfaceLow = Color(0xFF1A1A26);
  static const surfaceHi = Color(0xFF1F1F2E);
  static const f1Red = Color(0xFFE10600);

  static const gold = Color(0xFFC9A24A);
  static const goldDeep = Color(0xFF9E7C2E);
  static const goldSoft = Color(0xFFE2C47A);
  static const goldOnText = Color(0xFF1A1208);

  static Color goldBorder([double alpha = 0.25]) =>
      gold.withValues(alpha: alpha);
  static Color goldFill([double alpha = 0.10]) => gold.withValues(alpha: alpha);
}

class PremiumTextStyles {
  PremiumTextStyles._();

  static const family = 'TitilliumWeb';

  static const eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.4,
    color: PremiumColors.gold,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.25,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xB3FFFFFF),
    height: 1.45,
  );

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 13.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.8,
    color: PremiumColors.goldOnText,
  );
}
