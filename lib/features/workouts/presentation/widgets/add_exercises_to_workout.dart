import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/add_exercise_selector.dart';

class AddExercisesToWorkout extends ConsumerWidget {
  const AddExercisesToWorkout(this.workoutSessionId, {super.key});

  final int workoutSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return SizedBox(
      width: double.infinity,
      child: GradientCard(
        padding: EdgeInsets.zero,
        gradientVariant: AppGradients.card,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final addedExercise =
                  await AddExerciseSelector.openExercisePickerSheet(
                    context,
                  );
              if (addedExercise != null) {
                try {
                  await ref
                      .read(
                        workoutSessionExercisesProvider(
                          workoutSessionId,
                        ).notifier,
                      )
                      .addExercise(addedExercise);
                } catch (_) {
                  if (!context.mounted) return;
                  SnackBarError.show(
                    context,
                    'Could not add exercise. Please try again.',
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 24,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add exercise',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
