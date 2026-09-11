import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SolidButton(
      onPressed: isLoading ? () {} : onTap,
      isActive: isLoading,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s16,
      ),
      child: isLoading
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    color: AppColors.card,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'Please wait...',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: AppColors.card),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/google.png',
                  height: AppSpacing.s16,
                  width: AppSpacing.s16,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'Continue with Google',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: AppColors.card),
                ),
              ],
            ),
    );
  }
}
