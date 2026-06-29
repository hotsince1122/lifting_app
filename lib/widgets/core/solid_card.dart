import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class SolidCard extends StatelessWidget {
  const SolidCard({
    super.key,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(18),
    required this.child,
    this.borderColor = AppColors.cardBorder,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape as RoundedRectangleBorder?;
    final BorderRadius radius =
        shape?.borderRadius as BorderRadius? ?? BorderRadius.circular(24);

    return Card(
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: color,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
