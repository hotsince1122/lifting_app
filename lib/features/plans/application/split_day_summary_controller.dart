import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day_summary.dart';

final splitDaySummaryProvider =
    AsyncNotifierProvider.family<
      SplitDaySummaryController,
      SplitDaySummary,
      String
    >(SplitDaySummaryController.new);

class SplitDaySummaryController extends AsyncNotifier<SplitDaySummary> {
  SplitDaySummaryController(this.dayId);

  final String dayId;

  @override
  FutureOr<SplitDaySummary> build() async {
    final exercises = await ref.watch(plannedExercisesProvider(dayId).future);
    final muscleGroups = <String>{};

    for (final exercise in exercises) {
      final label = exercise.catalogExercise.muscleGroup;
      muscleGroups.add(label[0].toUpperCase() + label.substring(1));
    }

    return SplitDaySummary(
      exerciseCount: exercises.length,
      muscleGroups: muscleGroups,
    );
  }
}
