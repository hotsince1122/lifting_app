import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/utils/to_upper_first.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day_summary.dart';

final splitDaySummaryProvider = FutureProvider.family<SplitDaySummary, String>((
  ref,
  dayId,
) async {
  final exercises = await ref.watch(plannedExercisesProvider(dayId).future);
  final muscleGroups = <String>{};

  for (final exercise in exercises) {
    final label = exercise.catalogExercise.muscleGroup;
    muscleGroups.add(toUpperFirst(label));
  }

  return SplitDaySummary(
    exerciseCount: exercises.length,
    muscleGroups: muscleGroups,
  );
});
