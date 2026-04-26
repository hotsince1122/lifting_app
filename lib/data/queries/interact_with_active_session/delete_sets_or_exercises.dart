import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';

Future<bool> removeSetFromExerciseDb(
  String exerciseId,
  int exerciseOrderIndex,
  int setIndex,
  int workoutId,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    final rowsDeleted = await db.transaction((txn) async {
      final rowsDeleted = await txn.rawDelete(
        '''
      DELETE FROM active_session_sets
      WHERE workout_session_id = ?
        AND exercise_id = ?
        AND exercise_order_index = ?
        AND set_index = ?
      ''',
        [workoutId, exerciseId, exerciseOrderIndex, setIndex],
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
      final rowsDeleted = await txn.rawDelete(
        '''
        DELETE FROM active_session_sets
        WHERE workout_session_id = ?
          AND exercise_id = ?
          AND exercise_order_index = ?
        ''',
        [workoutId, exerciseId, exerciseOrderIndex],
      );

      await txn.rawUpdate(
        '''
        UPDATE active_session_sets
        SET exercise_order_index = -exercise_order_index
        WHERE workout_session_id = ?
          AND exercise_order_index > ?
        ''',
        [workoutId, exerciseOrderIndex],
      );

      await txn.rawUpdate(
        '''
        UPDATE active_session_sets
        SET exercise_order_index = -exercise_order_index - 1
        WHERE workout_session_id = ?
          AND exercise_order_index < 0
        ''',
        [workoutId],
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