import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    this.isActive = false,
    this.color = AppColors.primary,
    this.buttonWidth = double.infinity,
    this.buttonHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.borderColor = AppColors.cardBorder,
    required this.onPressed,
    required this.child,
  });

  final Widget child;
  final bool isActive;
  final VoidCallback onPressed;
  final Color color;
  final double buttonWidth;
  final double? buttonHeight;
  final EdgeInsetsGeometry padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(24));

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: buttonHeight,
        width: buttonWidth,
        child: AnimatedScale(
          scale: isActive ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: isActive ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: ElevatedButton(
              clipBehavior: Clip.antiAlias,
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: padding,
                elevation: 3,
                shadowColor: AppColors.cardShadow,
                backgroundColor: color,
                foregroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                side: BorderSide(color: borderColor, width: 1),
                shape: const RoundedRectangleBorder(borderRadius: radius),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
