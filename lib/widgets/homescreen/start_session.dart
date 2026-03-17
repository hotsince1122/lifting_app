import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class StartSession extends ConsumerWidget {
  const StartSession({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientCard(
      gradientVariant: Gradients.of(AppGradients.lightOne),
      child: SizedBox(height: 40),
    );
  }
}
