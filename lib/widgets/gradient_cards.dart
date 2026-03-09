import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.gradientVariant,
    this.padding = const EdgeInsets.all(16),
    required this.child,
  });

  final Widget child;
  final EdgeInsets padding;
  final LinearGradient gradientVariant;

  @override
  Widget build(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape as RoundedRectangleBorder?;
    final radius = shape?.borderRadius ?? BorderRadius.circular(24);

    return Card(
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: gradientVariant,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}