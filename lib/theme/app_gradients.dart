// import 'package:flutter/material.dart';
// import 'package:lifting_tracker_app/theme/app_colors.dart';

// enum AppGradients { darkOne, darkTwo, darkThree, lightOne }

// class Gradients {
//   static LinearGradient of(AppGradients variant) {
//     switch (variant) {
//       case AppGradients.darkOne:
//         return const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.bgSecondary,
//             Color.fromARGB(255, 44, 58, 77),
//             Color.fromARGB(255, 59, 66, 74),
//           ],
//           stops: [0.0, 0.45, 1.0],
//         );

//       case AppGradients.darkTwo:
//         return const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color.fromARGB(255, 44, 58, 77),
//             AppColors.bgSecondary,
//             Color.fromARGB(255, 48, 61, 80),
//           ],
//           stops: [0.0, 0.45, 1.0],
//         );

//       case AppGradients.darkThree:
//         return const LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.bgSecondary,
//             Color.fromARGB(255, 44, 58, 77),
//             AppColors.bgSecondary,
//             Color.fromARGB(255, 34, 49, 71),
//           ],
//           stops: [0.0, 0.35, 0.75, 1.0],
//         );

//       case AppGradients.lightOne:
//         return const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.accentLightBlue,
//             Color.fromARGB(255, 104, 115, 131),
//             Color.fromARGB(255, 94, 113, 139),
//           ],
//           stops: [0.0, 0.45, 1.0],
//         );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

enum AppGradients { card, softCard, deepCard, spotlightCard, primaryButton }

class AppThemeGradients {
  static LinearGradient of(AppGradients variant) {
    switch (variant) {
      case AppGradients.card:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.cardGradient],
        );

      case AppGradients.softCard:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardSoftStart, AppColors.cardSoftEnd],
        );

      case AppGradients.deepCard:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardDeepStart, AppColors.cardDeepEnd],
        );

      case AppGradients.spotlightCard:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardSpotlightStart, AppColors.cardSpotlightEnd],
        );

      case AppGradients.primaryButton:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        );
    }
  }
}
