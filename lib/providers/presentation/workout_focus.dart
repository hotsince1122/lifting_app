import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/models/view_model/workout_focus_vm.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_id.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
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

Future<WorkoutFocusVm> _loadNextWorkout() async {
  final db = await AppDatabases.getDatabase();

  final activeSplitDaysIds = await loadActiveSplitDaysIds(db);
  final nextCycleIndex = await loadNextCycleIndex(db, activeSplitDaysIds);
  final nextWorkoutData = await _loadNextWorkoutData(
    db,
    activeSplitDaysIds,
    nextCycleIndex,
  );

  final exercisesInNextWorkoutIds = await _loadExerciseIdsForWorkout(
    db,
    nextWorkoutData['id']!,
  );
  final muscleGroupInNextWorkout = await _loadMuscleGroups(
    db,
    exercisesInNextWorkoutIds,
  );

  return WorkoutFocusVm(
    workoutName: nextWorkoutData['name']!,
    muscleGroups: muscleGroupInNextWorkout,
    nrOfExercises: exercisesInNextWorkoutIds.length,
  );
}

Future<String?> returnWorkoutNameIfActiveWorkoutIsQuick(Ref ref) async {
  final activeSessionId = await ref.watch(activeSessionIdProvider.future);

  if (activeSessionId == null) return null;

  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery(
    '''
      SELECT day_id, workout_name
      FROM workout_sessions
      WHERE id = ?
      ''',
    [activeSessionId],
  );

  final row = data.first;

  if (row['day_id'] == null) {
    return row['workout_name'] as String;
  } else {
    return null;
  }
}

final workoutFocusProvider  =
    AsyncNotifierProvider<WorkoutFocusNotifier, WorkoutFocusVm>(
      WorkoutFocusNotifier.new,
    );

class WorkoutFocusNotifier extends AsyncNotifier<WorkoutFocusVm> {
  @override
  FutureOr<WorkoutFocusVm> build() async {
    ref.watch(activeSessionLifecycleProvider);

    final workoutName = await returnWorkoutNameIfActiveWorkoutIsQuick(ref);

    if (workoutName != null) {
      return WorkoutFocusVm(
        workoutName: workoutName,
        muscleGroups: null,
        nrOfExercises: null,
        isActiveQuickWorkout: true
      );
    }

    return _loadNextWorkout();
  }
}
