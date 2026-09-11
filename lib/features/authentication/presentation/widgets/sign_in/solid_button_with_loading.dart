import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';

class SolidButtonWithLoading extends StatelessWidget {
  const SolidButtonWithLoading({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.card,
    this.loadingLabel = 'Please wait...',
    super.key,
  });

  final String label;
  final bool isLoading;
  final Future<void> Function() onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SolidButton(
      isActive: isLoading,
      color: backgroundColor,
      onPressed: isLoading
          ? () {}
          : () async {
              await onPressed();
            },
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: !isLoading
            ? Text(
                label,
                key: ValueKey(label),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(color: textColor),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    loadingLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall!.copyWith(color: textColor),
                  ),
                ],
              ),
      ),
    );
  }
}
