import 'package:flutter/foundation.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';

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
