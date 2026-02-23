import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

enum GradientVariant { darkOne, darkTwo, darkThree, lightOne }

class Gradients {
  static LinearGradient of(GradientVariant variant) {
    switch (variant) {
      case GradientVariant.darkOne:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSecondary,
            Color.fromARGB(255, 44, 58, 77),
            Color.fromARGB(255, 59, 66, 74),
          ],
          stops: [0.0, 0.45, 1.0],
        );

      case GradientVariant.darkTwo:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 44, 58, 77),
            AppColors.bgSecondary,
            Color.fromARGB(255, 48, 61, 80),
          ],
          stops: [0.0, 0.45, 1.0],
        );

      case GradientVariant.darkThree:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSecondary,
            Color.fromARGB(255, 44, 58, 77),
            AppColors.bgSecondary,
            Color.fromARGB(255, 34, 49, 71),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        );

      case GradientVariant.lightOne:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentLightBlue,
            Color.fromARGB(255, 104, 115, 131),
            Color.fromARGB(255, 94, 113, 139),
          ],
          stops: [0.0, 0.45, 1.0],
        );
    }
  }
}
