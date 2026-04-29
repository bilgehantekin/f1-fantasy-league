import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  TextTheme tt(TextTheme src) => GoogleFonts.titilliumWebTextTheme(src).copyWith(
        // Display - massive, condensed, F1 style
        displayLarge: GoogleFonts.titilliumWeb(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.titilliumWeb(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        // Headlines - card titles, race name
        headlineLarge: GoogleFonts.titilliumWeb(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.titilliumWeb(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        // Titles - section headers
        titleLarge: GoogleFonts.titilliumWeb(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.titilliumWeb(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        labelLarge: GoogleFonts.titilliumWeb(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.titilliumWeb(
          fontSize: 15,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.titilliumWeb(
          fontSize: 14,
          color: Colors.white70,
        ),
      );

  return ThemeData(
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.carbon,
    useMaterial3: true,
    textTheme: tt(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.carbon,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.titilliumWeb(
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
        textStyle: GoogleFonts.titilliumWeb(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      labelStyle: GoogleFonts.titilliumWeb(fontWeight: FontWeight.w700),
      side: BorderSide.none,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.surfaceHi),
  );
}
