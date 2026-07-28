import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_day_summary_controller.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/view_data/workout_focus_view_data.dart';

final activeSplitDaysOptionsProvider =
    FutureProvider<List<WorkoutFocusViewData>>(
      (ref) => loadWorkoutFocusViewDataList(ref),
    );

Future<List<WorkoutFocusViewData>> loadWorkoutFocusViewDataList(Ref ref) async {
  final activeSplitDays = await ref.watch(activeSplitDaysProvider.future);
  final workouts = <WorkoutFocusViewData>[];

  for (final splitDay in activeSplitDays) {
    final summary = await ref.watch(
      splitDaySummaryProvider(splitDay.id).future,
    );
    var muscleGroups = summary.muscleGroups.join(' / ');

    if (muscleGroups.isNotEmpty && !muscleGroups.contains(' ')) {
      muscleGroups += ' focused';
    }

    workouts.add(
      WorkoutFocusViewData(
        workoutName: splitDay.name,
        muscleGroups: muscleGroups.isEmpty ? 'no muscle groups' : muscleGroups,
        exerciseCount: summary.exerciseCount,
        dayId: splitDay.id,
      ),
    );
  }

  return workouts;
}
