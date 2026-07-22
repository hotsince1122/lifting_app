import 'dart:ui';

import 'package:flutter/material.dart';

class TabBodyTransition extends StatelessWidget {
  const TabBodyTransition({
    required this.child,
    required this.animationKey,
    super.key,
  });

  final Widget child;
  final Object animationKey;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: 0.985, end: 1),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final t = (value - 0.985) / 0.015;
        final scale = lerpDouble(0.99, 1.0, t)!;

        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
