import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/gradient_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ContinueWithEmailButton extends StatelessWidget {
  const ContinueWithEmailButton({
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: isLoading ? () {} : onTap,
      isActive: isLoading,
      gradientVariant: AppGradients.card,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.envelopeSimple(),
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'Continue with email',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
