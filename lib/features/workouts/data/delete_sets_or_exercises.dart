import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart';
import 'package:sqflite/sqflite.dart';

Future<bool> removeSetFromExerciseDb(
  int workoutSessionSetId,
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

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
        [workoutSessionSetId, workoutSessionId],
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
        [workoutSessionSetId, workoutSessionId],
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
        [workoutSessionId, exerciseId, exerciseOrderIndex, setIndex],
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
        [workoutSessionId, exerciseId, exerciseOrderIndex],
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
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  try {
    final rowsDeleted = await db.transaction((txn) async {
      final exerciseOccurrenceIndex = await loadExerciseOccurrenceIndex(
        txn,
        workoutSessionId,
        exerciseId,
        exerciseOrderIndex,
      );

      if (exerciseOccurrenceIndex == null) return 0;

      final rowsDeleted = await _deleteExerciseRows(
        txn,
        workoutSessionId,
        exerciseId,
        exerciseOrderIndex,
      );

      if (rowsDeleted < 1) return rowsDeleted;

      await _compactExerciseOrderIndexes(
        txn,
        workoutSessionId,
        exerciseOrderIndex,
      );

      await _compactExerciseOccurrenceIndexes(
        txn,
        workoutSessionId,
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


Future<int> _deleteExerciseRows(
  DatabaseExecutor db,
  int workoutSessionId,
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
    [workoutSessionId, exerciseId, exerciseOrderIndex],
  );
}

Future<void> _compactExerciseOrderIndexes(
  DatabaseExecutor db,
  int workoutSessionId,
  int deletedExerciseOrderIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index
    WHERE workout_session_id = ?
      AND exercise_order_index > ?
    ''',
    [workoutSessionId, deletedExerciseOrderIndex],
  );

  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index - 1
    WHERE workout_session_id = ?
      AND exercise_order_index < 0
    ''',
    [workoutSessionId],
  );
}

Future<void> _compactExerciseOccurrenceIndexes(
  DatabaseExecutor db,
  int workoutSessionId,
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
    [workoutSessionId, exerciseId, deletedExerciseOccurrenceIndex],
  );
}
