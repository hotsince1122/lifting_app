import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class ProgressSpotlight extends ConsumerWidget {
  const ProgressSpotlight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: GradientCard(
        gradientVariant: Gradients.of(AppGradients.darkThree),
        child: Padding(
          padding: EdgeInsetsGeometry.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up_outlined,
                    size: 20,
                    color: AppColors.accentLightBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Progress Spotlight',
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentLightBlue.withAlpha(80),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: AppColors.accentLightBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Complete your first session to\nsee your progress here',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.accentLightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
