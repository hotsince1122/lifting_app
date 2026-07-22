import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

class ModalScaffold extends StatelessWidget {
  const ModalScaffold(
    this.child, {
    required this.height,
    required this.width,
    super.key,
  });

  final double height;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: MediaQuery.of(context).size.height * height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.card.withAlpha(253),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
