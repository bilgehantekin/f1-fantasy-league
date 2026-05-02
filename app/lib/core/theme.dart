import 'package:flutter/material.dart';

class AppColors {
  static const f1Red = Color(0xFFE10600);
  static const carbon = Color(0xFF0B0B12);
  static const surface = Color(0xFF15151E);
  static const surfaceHi = Color(0xFF1F1F2E);
  static const surfaceLow = Color(0xFF1A1A26);
  static const lockGreen = Color(0xFF00D26A);
  static const lockOrange = Color(0xFFFF9F1C);
  static const liveRed = Color(0xFFFF2D55);
  static const finished = Color(0xFF5E5E72);
}

ThemeData buildTheme() {
  final base = ColorScheme.dark(
    primary: AppColors.f1Red,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    onSurface: Colors.white,
    surfaceContainerHighest: AppColors.surfaceHi,
    secondary: AppColors.lockGreen,
    onSecondary: Colors.black,
  );

  const titilliumFamily = 'TitilliumWeb';

  TextTheme tt(TextTheme src) => src.copyWith(
    // Display - massive, condensed, F1 style (font-black = 900)
    displayLarge: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 48,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
      color: Colors.white,
      height: 1.0,
    ),
    displayMedium: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 36,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: Colors.white,
      height: 1.0,
    ),
    // Headlines - card titles, race name (font-black = 900)
    headlineLarge: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 24,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
    // Titles - section headers (font-bold = 700)
    titleLarge: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Colors.white,
    ),
    // Labels (font-black = 900)
    labelLarge: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    // Body text (normal weight = 400)
    bodyLarge: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
    ),
    bodySmall: TextStyle(
      fontFamily: titilliumFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
    ),
  );

  return ThemeData(
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.carbon,
    useMaterial3: true,
    textTheme: tt(ThemeData.dark().textTheme),
    fontFamily: titilliumFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.carbon,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: titilliumFamily,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        letterSpacing: -0.3,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLow,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.f1Red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(
          fontFamily: titilliumFamily,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: titilliumFamily,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.f1Red, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white60),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHi,
      selectedColor: AppColors.f1Red,
      labelStyle: TextStyle(
        fontFamily: titilliumFamily,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.surfaceHi),
  );
}
