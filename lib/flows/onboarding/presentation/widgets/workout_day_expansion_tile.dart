import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/features/plans/application/split_day_summary_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/add_exercise_selector.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/planned_exercises_list_view.dart';

class WorkoutDayExpansionTile extends ConsumerStatefulWidget {
  const WorkoutDayExpansionTile(this.workoutDay, {super.key});

  final SplitDay workoutDay;

  @override
  ConsumerState<WorkoutDayExpansionTile> createState() =>
      _WorkoutDayExpansionTileState();
}

class _WorkoutDayExpansionTileState
    extends ConsumerState<WorkoutDayExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final workoutDay = widget.workoutDay;

    final splitDaySummaryAsync = ref.watch(
      splitDaySummaryProvider(workoutDay.id),
    );

    return splitDaySummaryAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('An error has occured! Try again.')),
      data: (splitDaySummary) {
        final muscleGroups = splitDaySummary.muscleGroups.join(' / ');
        final exerciseCount = splitDaySummary.exerciseCount;

        return ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (isExpanded) {
            _isExpanded = isExpanded;
          },
          dense: true,
          title: Row(
            children: [
              Text(
                workoutDay.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '$exerciseCount selected',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: AppColors.secondary),
              ),
            ],
          ),

          subtitle: Text(
            muscleGroups.isNotEmpty
                ? muscleGroups
                : "Muscle groups will appear here",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: muscleGroups.isNotEmpty
                  ? AppColors.primary
                  : AppColors.onSurfaceMuted,
            ),
          ),

          controlAffinity: ListTileControlAffinity.leading,

          iconColor: AppColors.secondary,

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
              height: 1,
              color: AppColors.cardBorder,
              indent: AppSpacing.s16,
              endIndent: AppSpacing.s16,
            ),
            PlannedExercisesListView(
              workoutDay.id,
              includeBottomDivider: true,
              isTileDense: true,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final addedExercise =
                        await AddExerciseSelector.openExercisePickerSheet(
                          context,
                        );

                    if (!context.mounted || addedExercise == null) return;

                    try {
                      await ref
                          .read(
                            plannedExercisesProvider(workoutDay.id).notifier,
                          )
                          .addExerciseToDay(addedExercise.id);
                    } catch (_) {
                      if (!context.mounted) return;

                      SnackBarError.show(
                        context,
                        'Exercise could not be added. Try again.',
                      );
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
