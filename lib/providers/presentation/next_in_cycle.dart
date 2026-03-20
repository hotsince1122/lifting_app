import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/next_in_cycle_card_vm.dart';
import 'package:sqflite/sqflite.dart';

String _buildPlaceholder(int length) {
  return List<String>.generate(length, (_) => '?').join(', ');
}

Future<List<String>> _loadActiveSplitDaysIds(Database db) async {
  final data = await db.rawQuery('''
    SELECT sd.id AS id
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_active = 1
    ORDER BY sd.order_idx
    ''');

  return data.map((row) => row['id'] as String).toList();
}

Future<int> _loadNextCycleIndex(
  Database db,
  List<String> activeSplitDaysIds,
) async {
  final placeholder = _buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery('''
    SELECT cycle_index
    FROM completed_workouts
    WHERE day_id IN ($placeholder)
    ORDER BY performed_at DESC
    LIMIT 1
    ''', activeSplitDaysIds);

  if (data.isEmpty) return 0;

  return ((data.first['cycle_index'] as int) + 1) % activeSplitDaysIds.length;
}

Future<Map<String, String>> _loadNextWorkoutData(
  Database db,
  List<String> activeSplitDaysIds,
  int nextCycleIndex,
) async {
  final placeholder = _buildPlaceholder(activeSplitDaysIds.length);

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

  final placeholder = _buildPlaceholder(exerciseIds.length);

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

  final activeSplitDaysIds = await _loadActiveSplitDaysIds(db);
  final nextCycleIndex = await _loadNextCycleIndex(db, activeSplitDaysIds);
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
    return _loadNextWorkout();
  }
}
