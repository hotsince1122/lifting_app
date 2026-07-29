import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/domain/active_workout_session_status_key.dart';
import 'package:lifting_tracker_app/features/plans/domain/custom_split.dart';
import 'package:lifting_tracker_app/features/plans/domain/delete_split_plan_result.dart';

Future<int> addAndChangeToCustom(CustomSplit newSplit) async {
  final db = await AppDatabase.getDatabase();

  return await db.transaction((txn) async {
    await txn.update('split_plans', {'is_active': 0});

    final newSplitPlanId = await txn.insert('split_plans', {
      'name': newSplit.splitName,
      'is_preset': 0,
      'is_active': 1,
    });

    for (final splitDay in newSplit.splitDays) {
      await txn.insert('split_days', {
        'id': splitDay.id,
        'split_id': newSplitPlanId,
        'order_idx': splitDay.orderIndex,
        'name': splitDay.name,
      });
    }

    return newSplitPlanId;
  });
}

Future<void> changeToExisting(int splitId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawUpdate(
      '''
        UPDATE split_plans
        SET is_active = CASE
          WHEN id = ? THEN 1
          ELSE 0
        END;
        ''',
      [splitId],
    );
  });
}

Future<void> renameSplit(String newName, int splitId) async {
  final db = await AppDatabase.getDatabase();

  await db.rawUpdate(
    '''
      UPDATE split_plans
      SET name = ?
      WHERE id =?
      ''',
    [newName, splitId],
  );
}

Future<DeleteSplitPlanResult> deletePlan(int splitId) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction<DeleteSplitPlanResult>((txn) async {
    final activeSessions = await txn.rawQuery(
      '''
      SELECT 1
      FROM workout_sessions ws
      JOIN split_days sd ON sd.id = ws.day_id
      WHERE sd.split_id = ?
        AND ws.status = ?
      LIMIT 1
      ''',
      [splitId, activeWorkoutSessionStatus],
    );

    if (activeSessions.isNotEmpty) {
      return DeleteSplitPlanResult.sessionInSplitActive;
    }

    await txn.rawUpdate(
      '''
      UPDATE workout_sessions
      SET day_id = NULL
      WHERE day_id IN (
        SELECT id
        FROM split_days
        WHERE split_id = ?
      )
      ''',
      [splitId],
    );

    await txn.rawDelete(
      '''
      DELETE FROM day_exercises
      WHERE day_id IN (
        SELECT id
        FROM split_days
        WHERE split_id = ?
      )
      ''',
      [splitId],
    );

    await txn.rawDelete(
      '''
      DELETE FROM split_days
      WHERE split_id = ?
      ''',
      [splitId],
    );

    final deletedPlans = await txn.rawDelete(
      '''
      DELETE FROM split_plans
      WHERE id = ?
      ''',
      [splitId],
    );

    if (deletedPlans != 1) {
      throw Exception('Could not delete split plan $splitId.');
    }

    return DeleteSplitPlanResult.success;
  });
}
