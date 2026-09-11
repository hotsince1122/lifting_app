import 'package:flutter/material.dart';

class DisabledWhileLoading extends StatelessWidget {
  const DisabledWhileLoading({
    required this.isLoading,
    required this.child,
    super.key,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isLoading,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: isLoading ? 0.68 : 1,
        child: child,
      ),
    );
  }
}
