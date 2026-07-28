import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/can_finish_onboarding_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/widgets/workout_day_expansion_tile.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';

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
          padding: const EdgeInsets.fromLTRB(18, 32, 18, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: AppGradients.card,
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
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Workout days:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a day to get started.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final workoutDay in activeSplitDays) ...[
                        GradientCard(
                          padding: EdgeInsets.all(0),
                          gradientVariant: AppGradients.card,
                          child: WorkoutDayExpansionTile(
                            screenWidth,
                            workoutDay,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
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
    final canFinishOnboardingAsync = ref.watch(canFinishOnboardingProvider);

    return canFinishOnboardingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (canFinishOnboarding) {
        Widget skipButton = SizedBox(
          height: 20,
          child: TextButton(
            onPressed: () async {
              await ref.read(setupCompletionProvider.notifier).complete();
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Skip',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.onSurfaceMuted,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.onSurfaceMuted,
                decorationThickness: 1,
              ),
            ),
          ),
        );

        return Column(
          children: [
            SolidButton(
              isActive: !canFinishOnboarding,
              buttonHeight: 54,
              onPressed: !canFinishOnboarding
                  ? () {}
                  : () async {
                      await ref
                          .read(setupCompletionProvider.notifier)
                          .complete();
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Finish',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.background,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            canFinishOnboarding ? const SizedBox() : skipButton,
          ],
        );
      },
    );
  }
}
