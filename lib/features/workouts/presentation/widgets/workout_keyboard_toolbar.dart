import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';

class WorkoutKeyboardToolbar extends StatelessWidget {
  const WorkoutKeyboardToolbar({
    required this.onPrevious,
    required this.onNext,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarIconButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onPressed: onPrevious,
              ),
              const SizedBox(width: AppSpacing.s4),
              _ToolbarIconButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onPressed: onNext,
              ),
            ],
          ),
          const Spacer(),
          _ToolbarIconButton(
            icon: Icons.keyboard_hide_outlined,
            onPressed: onDismiss,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: emphasized ? AppColors.secondary : AppColors.onSurface,
        disabledForegroundColor: AppColors.onSurfaceMuted,
        backgroundColor: AppColors.onCardTransparent,
        disabledBackgroundColor: AppColors.onCardTransparent,
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
        shape: const CircleBorder(),
      ),
      icon: Icon(
        icon,
        size: 32,
        fontWeight: icon != Icons.keyboard_hide_outlined
            ? FontWeight.bold
            : FontWeight.normal,
      ),
    );
  }
}
