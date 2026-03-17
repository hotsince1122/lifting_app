import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class ProgressSpotlight extends ConsumerWidget {
  const ProgressSpotlight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: GradientCard(
        gradientVariant: Gradients.of(AppGradients.darkThree),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Progress Spotlight',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
