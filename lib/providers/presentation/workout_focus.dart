import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/data/queries/aux_funcs.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/models/view_model/workout_focus_vm.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_id.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/providers/persisted/picked_next_session_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<Map<String, String>> _loadNextWorkoutData(
  Database db,
  List<String> activeSplitDaysIds,
  int nextCycleIndex,
) async {
  final placeholder = buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery(
    '''
    SELECT id, name
    FROM split_days
    WHERE id IN ($placeholder)
      AND order_idx = ?
    ''',
    [...activeSplitDaysIds, nextCycleIndex],
  );

  final row = data.first;

  return {'id': row['id'] as String, 'name': row['name'] as String};
}

Future<List<String>> _loadExerciseIdsForWorkout(
  Database db,
  String workoutId,
) async {
  final data = await db.rawQuery(
    '''
    SELECT exercise_id
    FROM day_exercises
    WHERE day_id = ?
    ORDER BY order_idx
    ''',
    [workoutId],
  );

  return data.map((row) => row['exercise_id'] as String).toList();
}

Future<String?> _loadMuscleGroups(Database db, List<String> exerciseIds) async {
  if (exerciseIds.isEmpty) return null;

  final placeholder = buildPlaceholder(exerciseIds.length);

  final data = await db.rawQuery('''
    SELECT GROUP_CONCAT(muscle_group, ' / ') AS muscleGroups
    FROM (
      SELECT DISTINCT muscle_group
      FROM exercises
      WHERE id IN ($placeholder)
    )
    ''', exerciseIds);

  return data.first['muscleGroups'] as String?;
}

Future<WorkoutFocusVm> _loadNextWorkout(Ref ref) async {
  final db = await AppDatabase.getDatabase();

  final activeSplitDaysIds = await loadActiveSplitDaysIds(db);
  final pickedWorkoutDayId = await ref.read(pickedNextSessionProvider.future);
  final shouldUsePickedWorkout =
      pickedWorkoutDayId != null &&
      activeSplitDaysIds.contains(pickedWorkoutDayId);

  final String workoutDayId;
  final String nextWorkoutName;

  if (!shouldUsePickedWorkout) {
    final nextCycleIndex = await loadNextCycleIndex(db, activeSplitDaysIds);
    final nextWorkoutData = await _loadNextWorkoutData(
      db,
      activeSplitDaysIds,
      nextCycleIndex,
    );

    workoutDayId = nextWorkoutData['id']!;
    nextWorkoutName = nextWorkoutData['name']!;
  } else {
    workoutDayId = pickedWorkoutDayId;

    nextWorkoutName = await getWorkoutName(db, workoutDayId);
  }

  final exercisesInNextWorkoutIds = await _loadExerciseIdsForWorkout(
    db,
    workoutDayId,
  );
  final muscleGroupInNextWorkout = await _loadMuscleGroups(
    db,
    exercisesInNextWorkoutIds,
  );

  return WorkoutFocusVm(
    workoutName: nextWorkoutName,
    muscleGroups: muscleGroupInNextWorkout,
    nrOfExercises: exercisesInNextWorkoutIds.length,
    dayId: workoutDayId,
  );
}

Future<WorkoutFocusVm?> _loadActiveWorkoutFocus(Ref ref) async {
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
    return WorkoutFocusVm(
      workoutName: workoutName,
      muscleGroups: null,
      nrOfExercises: null,
      isActiveQuickWorkout: true,
    );
  }

  final exerciseIds = await _loadExerciseIdsForWorkout(db, dayId);
  final muscleGroups = await _loadMuscleGroups(db, exerciseIds);

  return WorkoutFocusVm(
    workoutName: workoutName,
    muscleGroups: muscleGroups,
    nrOfExercises: exerciseIds.length,
    dayId: dayId,
  );
}

final workoutFocusProvider =
    AsyncNotifierProvider<WorkoutFocusNotifier, WorkoutFocusVm>(
      WorkoutFocusNotifier.new,
    );

class WorkoutFocusNotifier extends AsyncNotifier<WorkoutFocusVm> {
  @override
  FutureOr<WorkoutFocusVm> build() async {
    ref.watch(activeSessionLifecycleProvider);
    ref.watch(pickedNextSessionProvider);

    final activeWorkoutFocus = await _loadActiveWorkoutFocus(ref);

    if (activeWorkoutFocus != null) return activeWorkoutFocus;

    return _loadNextWorkout(ref);
  }
}
