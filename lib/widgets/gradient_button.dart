import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    required this.gradientVariant,
    this.buttonWidth = double.infinity,
    this.buttonHeight,
    required this.child,
    this.borderColor = AppColors.cardBorder,
  });

  final Widget child;
  final bool isActive;
  final VoidCallback onPressed;
  final AppGradients gradientVariant;
  final double buttonWidth;
  final double? buttonHeight;
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
              style:
                  ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    elevation: 3,
                    shadowColor: AppColors.cardShadow,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(borderRadius: radius),
                  ).copyWith(
                    backgroundBuilder: (context, states, child) {
                      return Ink(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: AppThemeGradients.of(gradientVariant),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: child,
                      );
                    },
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
