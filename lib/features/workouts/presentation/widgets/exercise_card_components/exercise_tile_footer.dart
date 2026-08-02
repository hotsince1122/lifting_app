import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExerciseTileFooter extends StatelessWidget {
  const ExerciseTileFooter(this.exercise, {super.key});

  final WorkoutExercise exercise;

  static Widget exerciseTileFooterOnTap(
    WorkoutExercise exercise,
    WidgetRef ref,
    int workoutSessionId,
    BuildContext context,
  ) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              await ref
                  .read(
                    workoutSessionExercisesProvider(workoutSessionId).notifier,
                  )
                  .addSetToExercise(exercise);
            } catch (_) {
              if (!context.mounted) return;
              SnackBarError.show(
                context,
                'Could not add set. Please try again.',
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.add_circle_outline_rounded,
          size: 22,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(
          'Add Set',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        PhosphorIcon(
          PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
          size: 24,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.s24),
        PhosphorIcon(
          PhosphorIcons.star(PhosphorIconsStyle.fill),
          size: 24,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}
