import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/split_days.dart';
import 'package:lifting_tracker_app/providers/can_user_finish_setup.dart';
import 'package:lifting_tracker_app/providers/exercises_in_a_day.dart';
import 'package:lifting_tracker_app/providers/split_day_summary_tile.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/add_exercise_selector.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/added_exercises.dart';

class WorkoutDayExpansionTile extends ConsumerWidget {
  const WorkoutDayExpansionTile(this.screenWidth, this.workoutDay, {super.key});

  final double screenWidth;
  final SplitDay workoutDay;

  Future<Exercise?> openExercisePickerSheet(
    BuildContext context,
    double screenWidth,
  ) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      builder: (context) => AddExerciseSelector(screenWidth),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitDaySummaryAsync = ref.watch(
      splitDaySummaryProvider(workoutDay.id),
    );

    return splitDaySummaryAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('An error has occured! Try again.')),
      data: (splitDaySummary) {
        final muscleGroups = splitDaySummary.muscleGroups.join(' / ');
        final exerciseCount = splitDaySummary.exerciseCount;

        return ExpansionTile(
          title: Row(
            children: [
              Text(
                workoutDay.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '$exerciseCount selected',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightGray,
                ),
              ),
            ],
          ),

          subtitle: Text(
            muscleGroups.isNotEmpty
                ? muscleGroups
                : "Muscle groups will appear here",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: AppColors.accentLightGray),
          ),

          controlAffinity: ListTileControlAffinity.leading,

          iconColor: AppColors.accentLightGray,

          // backgroundColor: AppColors.bgSecondary,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),

          children: [
            Divider(
                      height: 0.5,
                      color: AppColors.accentLightGray,
                      indent: 16,
                      endIndent: 16,
                    ),
            AddedExercises(workoutDay.id),
            Divider(
                      height: 0.5,
                      color: AppColors.accentLightGray,
                      indent: 16,
                      endIndent: 16,
                    ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final addedExercise = await openExercisePickerSheet(
                      context,
                      screenWidth,
                    );

                    if (addedExercise != null) {
                      await ref
                          .read(exercisesInADayProvider(workoutDay.id).notifier)
                          .addExerciseToDay(workoutDay.id, addedExercise.id);
                      await ref
                          .read(splitDaySummaryProvider(workoutDay.id).notifier)
                          .refresh();
                      await ref.read(canUserFinishSetupProvider.notifier).refresh();
                    }
                  },
                  label: Text('Add exercise'),
                  icon: Icon(Icons.add_circle_outline_rounded),
                  iconAlignment: IconAlignment.start,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}