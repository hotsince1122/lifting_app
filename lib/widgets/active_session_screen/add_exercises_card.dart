import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector.dart';

class AddExercisesCard extends ConsumerWidget {
  const AddExercisesCard(this.workoutSessionId, {super.key});

  final int workoutSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                    screenWidth,
                  );
              if (addedExercise != null) {
                await ref
                    .read(exercisesAndSetsProvider(workoutSessionId).notifier)
                    .addExercise(addedExercise);
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





// Text('Add exercise'),
// Icon(Icons.add_circle_outline_rounded),

// final addedExercise = await openExercisePickerSheet(
              //   context,
              //   screenWidth,
              // );
          
              // if (addedExercise != null) {
              //   await ref
              //       .read(exercisesInADayProvider(workoutDay.id).notifier)
              //       .addExerciseToDay(workoutDay.id, addedExercise.id);
              //   await ref
              //       .read(splitDaySummaryProvider(workoutDay.id).notifier)
              //       .refresh();
              //   await ref.read(canUserFinishSetupProvider.notifier).refresh();
              // }