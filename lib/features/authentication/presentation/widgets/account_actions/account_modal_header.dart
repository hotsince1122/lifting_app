import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountModalHeader extends StatelessWidget {
  const AccountModalHeader({
    required this.title,
    required this.body,
    this.icon,
    this.accentColor = AppColors.primary,
    super.key,
  });

  final String title;
  final String body;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon case final icon?) ...[
          Container(
            width: AppSpacing.s40,
            height: AppSpacing.s40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.s12),
              border: Border.all(color: accentColor.withValues(alpha: 0.40)),
            ),
            child: PhosphorIcon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
