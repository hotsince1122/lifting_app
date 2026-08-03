import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

class RestTimerAdjustmentButton extends StatelessWidget {
  const RestTimerAdjustmentButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: AppColors.cardBorder),
          backgroundColor: AppColors.onCardTransparent,
          foregroundColor: AppColors.onSurface,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
