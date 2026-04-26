import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExerciseTileFooter extends StatelessWidget {
  const ExerciseTileFooter(this.exercise, {super.key});

  final Exercise exercise;

  static Widget exerciseTileFooterOnTap(
    Exercise exercise,
    WidgetRef ref,
    int activeSessionId,
  ) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref
                .read(exercisesAndSetsProvider(activeSessionId).notifier)
                .addSetToExercise(exercise);
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
        const SizedBox(width: 6),
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
        const SizedBox(width: 24),
        PhosphorIcon(
          PhosphorIcons.star(PhosphorIconsStyle.fill),
          size: 24,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}
