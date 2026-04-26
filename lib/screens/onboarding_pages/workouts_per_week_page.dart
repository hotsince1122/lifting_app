import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';

import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';

class WorkoutsPerWeekPage extends StatelessWidget {
  const WorkoutsPerWeekPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientCard(
            gradientVariant: AppGradients.card,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Welcome to Focus Lifts',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Let's get you set up.",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Anything you choose now can\n be changed later.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: AppColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GradientCard(
            gradientVariant: AppGradients.card,
            child: Center(
              child: Column(
                children: [
                  Text(
                    "How many days do you train per week?",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 20),
                  _WorkoutsPerWeekSlider(),
                ],
              ),
            ),
          ),
          Spacer(),
          SolidButton(
            isActive: false,
            buttonHeight: 54,
            onPressed: () => controller.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: AppColors.background),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: AppColors.background,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsPerWeekSlider extends ConsumerWidget {
  const _WorkoutsPerWeekSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsPerWeekAsync = ref.watch(weeklyWorkoutProgressProvider);

    return workoutsPerWeekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (weeklyWorkoutProgress) {
        final target = weeklyWorkoutProgress.target;

        return Slider(
          value: target.toDouble(),
          max: 7,
          min: 1,
          divisions: 6,
          activeColor: AppColors.onSurface,
          inactiveColor: AppColors.surface,
          label: '$target day${target > 1 ? 's' : ''}',
          thumbColor: AppColors.primary,
          onChanged: (value) {
            ref
                .read(weeklyWorkoutProgressProvider.notifier)
                .saveNewTarget(value.toInt());
          },
        );
      },
    );
  }
}
