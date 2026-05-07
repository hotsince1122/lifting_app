import 'package:flutter/foundation.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

Future<bool> toggleSetWarmupInDb (
  int activeSessionSetId,
  int workoutSessionId,
) async {

  final db = await AppDatabases.getDatabase();

  try {
    final rowsUpdated = await db.transaction(
      (txn) async {
        final rowsUpdated = await txn.rawUpdate(
          '''
          UPDATE active_session_sets
          SET is_warmup = CASE
            WHEN is_warmup = 0 THEN 1
            WHEN is_warmup = 1 THEN 0
          END
          WHERE id = ?
            AND workout_session_id = ?
          ''',
          [activeSessionSetId, workoutSessionId]
        );

        return rowsUpdated;
      }
    );

    if (rowsUpdated >= 1) return true;
    
    return false;
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}

Future<bool> reorderExercisesInDb(
  List<Exercise> reorderedExercises,
  int sessionId,
) async {
  final setUpdates = <({int activeSessionSetId, int orderIndex})>[];

  for (final exercise in reorderedExercises) {
    final orderIndex = exercise.orderIndex;
    if (orderIndex == null) return false;

    for (final set in exercise.sets) {
      final activeSessionSetId = set.activeSessionSetId;
      if (activeSessionSetId == null) return false;

      setUpdates.add((
        activeSessionSetId: activeSessionSetId,
        orderIndex: orderIndex,
      ));
    }
  }

  if (setUpdates.isEmpty) return true;

  final db = await AppDatabases.getDatabase();

  try {
    final rowsMovedToTempIndexes = await db.transaction((txn) async {
      var updatedRows = 0;

      for (final update in setUpdates) {
        updatedRows += await txn.rawUpdate(
          '''
          UPDATE active_session_sets
          SET exercise_order_index = ?
          WHERE id = ?
            AND workout_session_id = ?
          ''',
          [
            -(update.orderIndex + 1),
            update.activeSessionSetId,
            sessionId,
          ],
        );
      }

      if (updatedRows != setUpdates.length) {
        throw StateError('Some active session sets were not found.');
      }

      final rowsMovedToFinalIndexes = await txn.rawUpdate(
        '''
        UPDATE active_session_sets
        SET exercise_order_index = -exercise_order_index - 1
        WHERE workout_session_id = ?
          AND exercise_order_index < 0
        ''',
        [sessionId],
      );

      if (rowsMovedToFinalIndexes != setUpdates.length) {
        throw StateError('Some active session sets were not finalized.');
      }

      return updatedRows;
    });

    return rowsMovedToTempIndexes == setUpdates.length;
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}
