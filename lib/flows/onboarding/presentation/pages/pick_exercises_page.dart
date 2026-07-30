import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/can_finish_onboarding_provider.dart';
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
    final activeSplitDaysAsync = ref.watch(activeSplitDaysProvider);

    return activeSplitDaysAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (activeSplitDays) {
        final dayIds = activeSplitDays.map((splitDay) => splitDay.id).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
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
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      "Tap a day to get started.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.s24),

              Text(
                'Workout days:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.s12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final workoutDay in activeSplitDays) ...[
                        GradientCard(
                          key: ValueKey(workoutDay.id),
                          padding: EdgeInsets.all(0),
                          gradientVariant: AppGradients.card,
                          child: WorkoutDayExpansionTile(workoutDay),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
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
          height: AppSpacing.s20,
          child: TextButton(
            onPressed: () async {
              try {
                await ref.read(setupCompletionProvider.notifier).complete();
              } catch (_) {
                if (!context.mounted) return;
                SnackBarError.show(context, 'Could not skip. Try again!');
              }
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
            canFinishOnboarding ? const SizedBox() : skipButton,
            const SizedBox(height: AppSpacing.s8),
            SolidButton(
              isActive: !canFinishOnboarding,
              buttonHeight: 54,
              onPressed: !canFinishOnboarding
                  ? () {}
                  : () async {
                      try {
                        await ref
                            .read(setupCompletionProvider.notifier)
                            .complete();
                      } catch (_) {
                        if (!context.mounted) return;
                        SnackBarError.show(
                          context,
                          'Could not finish setup. Try again!',
                        );
                      }
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
                  SizedBox(width: AppSpacing.s8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
