import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_id_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/next_session_preview_provider.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/view_data/workout_focus_view_data.dart';

Future<({int exerciseCount, String? muscleGroups})> _loadExerciseSummary(
  Ref ref,
  String dayId,
) async {
  final exercises = await ref.watch(plannedExercisesProvider(dayId).future);
  final muscleGroups = exercises
      .map((exercise) => exercise.catalogExercise.muscleGroup)
      .toSet()
      .join(' / ');

  return (
    exerciseCount: exercises.length,
    muscleGroups: muscleGroups.isEmpty ? null : muscleGroups,
  );
}

Future<WorkoutFocusViewData> _loadNextWorkout(Ref ref) async {
  final nextSession = await ref.watch(nextSessionPreviewProvider.future);
  final exerciseSummary = await _loadExerciseSummary(ref, nextSession.dayId);

  return WorkoutFocusViewData(
    workoutName: nextSession.workoutName,
    muscleGroups: exerciseSummary.muscleGroups,
    exerciseCount: exerciseSummary.exerciseCount,
    dayId: nextSession.dayId,
  );
}

Future<WorkoutFocusViewData?> _loadActiveWorkoutFocus(Ref ref) async {
  final activeSessionId = await ref.watch(activeSessionIdProvider.future);

  if (activeSessionId == null) return null;

  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
      SELECT day_id, workout_name
      FROM workout_sessions
      WHERE id = ?
      ''',
    [activeSessionId],
  );

  if (data.isEmpty) return null;

  final row = data.first;
  final workoutName = row['workout_name'] as String;
  final dayId = row['day_id'] as String?;

  if (dayId == null) {
    return WorkoutFocusViewData(
      workoutName: workoutName,
      muscleGroups: null,
      exerciseCount: null,
      isActiveQuickWorkout: true,
    );
  }

  final exerciseSummary = await _loadExerciseSummary(ref, dayId);

  return WorkoutFocusViewData(
    workoutName: workoutName,
    muscleGroups: exerciseSummary.muscleGroups,
    exerciseCount: exerciseSummary.exerciseCount,
    dayId: dayId,
  );
}

final workoutFocusProvider = FutureProvider<WorkoutFocusViewData>((ref) async {
  ref.watch(activeSessionLifecycleProvider);
  ref.watch(pickedNextSessionProvider);

  final activeWorkoutFocus = await _loadActiveWorkoutFocus(ref);

  if (activeWorkoutFocus != null) return activeWorkoutFocus;

  return _loadNextWorkout(ref);
});
