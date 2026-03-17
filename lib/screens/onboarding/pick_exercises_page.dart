import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_days.dart';
import 'package:lifting_tracker_app/providers/presentation/can_user_finish_setup.dart';
import 'package:lifting_tracker_app/screens/home.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
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

    final activeSplitDaysAsync = ref.watch(activeSplitDaysProvider);

    return activeSplitDaysAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (activeSplitDays) {
        final dayIds = activeSplitDays.map((splitDay) => splitDay.id).toList();

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
                      for (final workoutDay in activeSplitDays) ...[
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
              _FinishOnboardingButton(dayIds),
            ],
          ),
        );
      },
    );
  }
}

class _FinishOnboardingButton extends ConsumerWidget {
  const _FinishOnboardingButton(this.dayIds);

  final List<String> dayIds;

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
            onPressed: () => Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (context) => Home())),
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
                  : () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => Home()),
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
