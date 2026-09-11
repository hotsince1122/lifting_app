import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';

final exerciseSelectedForEachDayProvider = FutureProvider<bool>((ref) async {
  final activeSplitDays = await ref.watch(activeSplitDaysProvider.future);
  if (activeSplitDays.isEmpty) return false;

  for (final splitDay in activeSplitDays) {
    final exercises = await ref.watch(
      plannedExercisesProvider(splitDay.id).future,
    );

    if (exercises.isEmpty) return false;
  }

  return true;
});
