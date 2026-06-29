import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_focus.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/core/gradient_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WorkoutFocusSection extends ConsumerWidget {
  const WorkoutFocusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatusAsync = ref.watch(activeSessionLifecycleProvider);
    Widget cardTitle = sessionStatusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (isSessionActive) => Text(
        isSessionActive ? 'Current session' : 'Next in cycle',
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );

    return AspectRatio(
      aspectRatio: 1.15,
      child: GradientCard(
        gradientVariant: AppGradients.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.navigate_next_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                cardTitle,
              ],
            ),
            const SizedBox(height: 16),
            _NextSessionInfoAsync(),
          ],
        ),
      ),
    );
  }
}

class _NextSessionInfoAsync extends ConsumerWidget {
  const _NextSessionInfoAsync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutFocusInfoAsync = ref.watch(workoutFocusProvider);

    Widget emptyState = Text(
      'No exercises added yet. Start now and build as you go.',
      style: Theme.of(
        context,
      ).textTheme.labelMedium!.copyWith(color: AppColors.onSurfaceMuted),
    );

    Widget quickSessionState = Text(
      "This workout won't affect your split.",
      style: Theme.of(
        context,
      ).textTheme.labelMedium!.copyWith(color: AppColors.onSurfaceMuted),
    );

    return workoutFocusInfoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (workoutFocusInfo) {
        if (workoutFocusInfo.muscleGroups == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workoutFocusInfo.workoutName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              workoutFocusInfo.isActiveQuickWorkout
                  ? quickSessionState
                  : emptyState,
            ],
          );
        }

        final String nrOfExercisesLabel =
            '${workoutFocusInfo.nrOfExercises} exercise${workoutFocusInfo.nrOfExercises == 1 ? '' : 's'} planned.';

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workoutFocusInfo.workoutName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 6),

              Text(
                workoutFocusInfo.muscleGroups!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: AppColors.secondary),
              ),

              const SizedBox(height: 6),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.barbell(),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    nrOfExercisesLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
