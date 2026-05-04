import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:sqflite/sqflite.dart';

Future<bool> removeSetFromExerciseDb(
  int activeSessionSetId,
  int workoutId,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    final rowsDeleted = await db.transaction((txn) async {
      final setData = await txn.rawQuery(
        '''
      SELECT exercise_id,
        exercise_order_index,
        set_index
      FROM active_session_sets
      WHERE id = ?
        AND workout_session_id = ?
      LIMIT 1
      ''',
        [activeSessionSetId, workoutId],
      );

      if (setData.isEmpty) return 0;

      final exerciseId = setData.first['exercise_id'] as String;
      final exerciseOrderIndex = setData.first['exercise_order_index'] as int;
      final setIndex = setData.first['set_index'] as int;

      final rowsDeleted = await txn.rawDelete(
        '''
      DELETE FROM active_session_sets
      WHERE id = ?
        AND workout_session_id = ?
      ''',
        [activeSessionSetId, workoutId],
      );

      await txn.rawUpdate(
        '''
      UPDATE active_session_sets
      SET set_index = -set_index
      WHERE workout_session_id = ?
        AND exercise_id = ?
        AND exercise_order_index = ?
        AND set_index > ?
      ''',
        [workoutId, exerciseId, exerciseOrderIndex, setIndex],
      );

      await txn.rawUpdate(
        '''
      UPDATE active_session_sets
      SET set_index = -set_index - 1
      WHERE workout_session_id = ?
        AND exercise_id = ?
        AND exercise_order_index = ?
        AND set_index < 0
      ''',
        [workoutId, exerciseId, exerciseOrderIndex],
      );

      return rowsDeleted;
    });

    if (rowsDeleted >= 1) {
      return true;
    } else {
      return false;
    }
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}

Future<bool> deleteExerciseFromDb(
  String exerciseId,
  int exerciseOrderIndex,
  int workoutId,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    final rowsDeleted = await db.transaction((txn) async {
      final exerciseOccurrenceIndex = await _loadExerciseOccurrenceIndex(
        txn,
        workoutId,
        exerciseId,
        exerciseOrderIndex,
      );

      if (exerciseOccurrenceIndex == null) return 0;

      final rowsDeleted = await _deleteExerciseRows(
        txn,
        workoutId,
        exerciseId,
        exerciseOrderIndex,
      );

      if (rowsDeleted < 1) return rowsDeleted;

      await _compactExerciseOrderIndexes(
        txn,
        workoutId,
        exerciseOrderIndex,
      );

      await _compactExerciseOccurrenceIndexes(
        txn,
        workoutId,
        exerciseId,
        exerciseOccurrenceIndex,
      );

      return rowsDeleted;
    });

    if (rowsDeleted >= 1) {
      return true;
    } else {
      return false;
    }
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}

Future<int?> _loadExerciseOccurrenceIndex(
  DatabaseExecutor db,
  int workoutId,
  String exerciseId,
  int exerciseOrderIndex,
) async {
  final data = await db.rawQuery(
    '''
    SELECT exercise_occurrence_index
    FROM active_session_sets
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_order_index = ?
    LIMIT 1
    ''',
    [workoutId, exerciseId, exerciseOrderIndex],
  );

  if (data.isEmpty) return null;

  return data.first['exercise_occurrence_index'] as int;
}

Future<int> _deleteExerciseRows(
  DatabaseExecutor db,
  int workoutId,
  String exerciseId,
  int exerciseOrderIndex,
) {
  return db.rawDelete(
    '''
    DELETE FROM active_session_sets
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_order_index = ?
    ''',
    [workoutId, exerciseId, exerciseOrderIndex],
  );
}

Future<void> _compactExerciseOrderIndexes(
  DatabaseExecutor db,
  int workoutId,
  int deletedExerciseOrderIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index
    WHERE workout_session_id = ?
      AND exercise_order_index > ?
    ''',
    [workoutId, deletedExerciseOrderIndex],
  );

  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index - 1
    WHERE workout_session_id = ?
      AND exercise_order_index < 0
    ''',
    [workoutId],
  );
}

Future<void> _compactExerciseOccurrenceIndexes(
  DatabaseExecutor db,
  int workoutId,
  String exerciseId,
  int deletedExerciseOccurrenceIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_occurrence_index = exercise_occurrence_index - 1
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_occurrence_index > ?
    ''',
    [workoutId, exerciseId, deletedExerciseOccurrenceIndex],
  );
}
