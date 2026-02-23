import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    required this.gradientVariant,
    this.buttonWidth = double.infinity,
    this.buttonHight,
    required this.child,
  });

  final Widget child;
  final bool isActive;
  final void Function() onPressed;
  final LinearGradient gradientVariant;
  final double buttonWidth;
  final double? buttonHight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: buttonHight,
        width: buttonWidth,
        child: AnimatedScale(
          scale: isActive ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: isActive ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: ElevatedButton(
              clipBehavior: Clip.antiAlias,
              onPressed: () {
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundBuilder: (context, states, child) => Ink(
                  decoration: BoxDecoration(
                    gradient: gradientVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: child,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
