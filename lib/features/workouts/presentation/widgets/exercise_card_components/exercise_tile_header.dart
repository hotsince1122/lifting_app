import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExerciseTileHeader extends StatelessWidget {
  const ExerciseTileHeader(this.exercise, this.iconSize, {super.key});

  final WorkoutExercise exercise;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          exercise.catalogExercise.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        PhosphorIcon(
          PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
          size: iconSize,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}
