import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    required this.gradientVariant,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;
  final LinearGradient gradientVariant;

  @override
  Widget build(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape as RoundedRectangleBorder?;
    final radius = shape?.borderRadius ?? BorderRadius.circular(20);

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