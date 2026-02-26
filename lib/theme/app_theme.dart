import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.bgMain,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.bgMain,
          onSurface: AppColors.accentLightWhite,

          surfaceDim: AppColors.bgSecondary,
          surfaceContainerLow: AppColors.bgSecondary,

          // surfaceContainer: AppColors.bgMain,
          primary: AppColors.accentLightWhite,
          secondary: AppColors.accentLightGray,

          onPrimary: AppColors.accentLightWhite,
          onSecondary: Colors.black,
        ),

    scaffoldBackgroundColor: AppColors.bgMain,

    //aparent se poate da copyWith la fontWeight doar in sus, nu in jos,
    //deci era bine daca fontWeight-ul era lasat normal in theme

    textTheme: GoogleFonts.latoTextTheme().copyWith(
      displayLarge: GoogleFonts.lato(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.lato(fontSize: 30, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.lato(fontSize: 26, fontWeight: FontWeight.w700),

      headlineLarge: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w600), //Pentru: titluri de ecran și secțiuni importante
      headlineSmall: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),

      titleLarge: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),  //Pentru: titluri de card, titlu de exercițiu, elemente principale într-un card
      titleMedium: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),

      bodyLarge: GoogleFonts.lato(fontSize: 16, height: 1.3), //Pentru: text normal important, descrieri scurte, value text
      bodyMedium: GoogleFonts.lato(fontSize: 14, height: 1.3),  //Pentru: text normal secundar, liste, rânduri
      bodySmall: GoogleFonts.lato(fontSize: 12, height: 1.3), //Pentru: hint-uri, micro-copy, subtext, note

      labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),  //Pentru: butoane, chip-uri, CTA text
      labelMedium: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600),
    ),

    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
    ), 

    sliderTheme: SliderThemeData(
      // ignore: deprecated_member_use
      year2023: false,
      valueIndicatorColor: AppColors.darkCardsMain,
    ),
  );
}
