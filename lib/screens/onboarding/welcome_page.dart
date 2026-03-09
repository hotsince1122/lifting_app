import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/workouts_per_week.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';

import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientCard(
            gradientVariant: Gradients.of(AppGradients.darkOne),
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
                      color: AppColors.accentLightGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Anything you choose now can be\n changed later.',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: AppColors.accentLightBlue.withAlpha(180),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GradientCard(
            gradientVariant: Gradients.of(AppGradients.darkThree),
            child: Center(
              child: Column(
                children: [
                  Text(
                    "How many days do you train per week?",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _WorkoutsPerWeekSlider(),
                ],
              ),
            ),
          ),
          Spacer(),
          GradientButton(
            isActive: false,
            buttonHight: 48,
            onPressed: () => controller.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            ),
            gradientVariant: Gradients.of(AppGradients.lightOne),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded),
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
    final workoutsPerWeekAsync = ref.watch(workoutsPerWeekProvider);

    return workoutsPerWeekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (workoutsPerWeek) {
        return Slider(
          value: workoutsPerWeek.toDouble(),
          max: 7,
          min: 1,
          divisions: 6,
          activeColor: AppColors.accentLightWhite,
          inactiveColor: AppColors.darkCardsSecodary,
          label: '$workoutsPerWeek day${workoutsPerWeek > 1 ? 's' : ''}',
          thumbColor: AppColors.accentLightBlue,
          onChanged: (value) {
            ref.read(workoutsPerWeekProvider.notifier).save(value.toInt());
          },
        );
      },
    );
  }
}
