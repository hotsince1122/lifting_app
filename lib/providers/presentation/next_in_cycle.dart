import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/models/view_model/next_in_cycle_card_vm.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';
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

Future<NextInCycleCardVm> _loadNextWorkout() async {
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

  return NextInCycleCardVm(
    workoutName: nextWorkoutData['name']!,
    muscleGroups: muscleGroupInNextWorkout,
    nrOfExercises: exercisesInNextWorkoutIds.length,
  );
}

final nextInCycleProvider =
    AsyncNotifierProvider<NextInCycleNotifier, NextInCycleCardVm>(
      NextInCycleNotifier.new,
    );

class NextInCycleNotifier extends AsyncNotifier<NextInCycleCardVm> {
  @override
  FutureOr<NextInCycleCardVm> build() {
    ref.watch(currentSessionStatusProvider);
    return _loadNextWorkout();
  }
}
