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
