import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/can_user_finish_setup.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/providers/split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/workout_day_expansion_tile.dart';

class PickExercisesPage extends ConsumerWidget {
  const PickExercisesPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    final splitPlanAsync = ref.watch(splitPlanProvider);

    return splitPlanAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (splitPlan) {
        final dayIds = splitPlan.map((splitDay) => splitDay.id).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: Gradients.of(AppGradients.darkTwo),
                child: Column(
                  children: [
                    Text(
                      "Select your exercises",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "For each workout day.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Workout days:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a day to get started.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue.withAlpha(180),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final workoutDay in splitPlan) ...[
                        GradientCard(
                          padding: EdgeInsets.all(0),
                          gradientVariant: Gradients.of(AppGradients.darkThree),
                          child: WorkoutDayExpansionTile(
                            screenWidth,
                            workoutDay,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _FinishOnboardingButton(dayIds, controller),
            ],
          ),
        );
      },
    );
  }
}

class _FinishOnboardingButton extends ConsumerWidget {
  const _FinishOnboardingButton(this.dayIds, this.controller);

  final List<String> dayIds;
  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUserFinishSetupAsync = ref.watch(canUserFinishSetupProvider);

    return canUserFinishSetupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (canUserFinishSetup) {
        Widget skipButton = SizedBox(
          height: 20,
          child: TextButton(
            onPressed: () => controller.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Skip',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.accentLightBlue.withAlpha(180),
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accentLightBlue.withAlpha(180),
                decorationThickness: 1,
              ),
            ),
          ),
        );

        return Column(
          children: [
            GradientButton(
              isActive: !canUserFinishSetup,
              buttonHight: 48,
              onPressed: !canUserFinishSetup
                  ? () {}
                  : () => controller.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
              gradientVariant: Gradients.of(AppGradients.lightOne),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finish', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
            const SizedBox(height: 6),
            canUserFinishSetup ? const SizedBox() : skipButton,
          ],
        );
      },
    );
  }
}
