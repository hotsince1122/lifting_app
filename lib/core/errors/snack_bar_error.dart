import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

class SnackBarError extends SnackBar {
  SnackBarError(String message, BuildContext context, {super.key})
    : super(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.card,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBarError(message, context));
  }
}
