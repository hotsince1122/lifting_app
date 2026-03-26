import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.background,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.background,
          onSurface: AppColors.onSurface,

          surfaceDim: AppColors.onSurfaceMuted,
          surfaceContainerLow: AppColors.background,

          // surfaceContainer: AppColors.bgMain,
          primary: AppColors.primary,
          secondary: AppColors.secondary,

          onPrimary: AppColors.onSurface,
          onSecondary: Colors.black,
        ),

    scaffoldBackgroundColor: AppColors.background,

    //aparent se poate da copyWith la fontWeight doar in sus, nu in jos,
    //deci era bine daca fontWeight-ul era lasat normal in theme

    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),

      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600), //Pentru: titluri de ecran și secțiuni importante
      headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),

      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),  //Pentru: titluri de card, titlu de exercițiu, elemente principale într-un card
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),

      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.3), //Pentru: text normal important, descrieri scurte, value text
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.3),  //Pentru: text normal secundar, liste, rânduri
      bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.3), //Pentru: hint-uri, micro-copy, subtext, note

      labelLarge: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),  //Pentru: butoane, chip-uri, CTA text
      labelMedium: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600),
    ),

    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      margin: EdgeInsets.zero,
    ),

    sliderTheme: SliderThemeData(
      // ignore: deprecated_member_use
      year2023: false,
      valueIndicatorColor: AppColors.background,
    ),
  );
}