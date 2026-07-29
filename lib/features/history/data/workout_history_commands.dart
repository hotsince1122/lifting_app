import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

Future<void> clearActiveSessionSets(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawDelete(
      '''
        DELETE FROM active_session_sets
        WHERE workout_session_id = ?
        ''',
      [workoutSessionId],
    );
  });
}

Future<void> saveEditedWorkout(
  int workoutSessionId,
  String normalizedWorkoutName,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawUpdate(
      '''
          UPDATE workout_sessions
          SET workout_name = ?
          WHERE id = ?
          ''',
      [normalizedWorkoutName, workoutSessionId],
    );

    await txn.rawDelete(
      '''
          DELETE FROM logged_sets
          WHERE session_id = ?
          ''',
      [workoutSessionId],
    );

    final setsData = await txn.rawQuery(
      '''
          SELECT exercise_id AS ex_id,
            workout_session_id AS session_id,
            actual_weight AS weight,
            actual_repetitions AS repetitions,
            actual_notes AS notes,
            set_index,
            exercise_order_index AS order_index,
            exercise_occurrence_index,
            is_warmup
          FROM active_session_sets
          WHERE workout_session_id = ?
            AND actual_weight IS NOT NULL
            AND actual_repetitions IS NOT NULL
          ORDER BY exercise_order_index, set_index
          ''',
      [workoutSessionId],
    );

    final batch = txn.batch();
    for (final setData in setsData) {
      batch.insert('logged_sets', setData);
    }
    await batch.commit(noResult: true);

    await txn.rawDelete(
      '''
          DELETE FROM active_session_sets
          WHERE workout_session_id = ?
          ''',
      [workoutSessionId],
    );
  });
}

Future<({DateTime finishedTime, bool hasAnotherWorkoutOnSameDay})>
deleteWorkout(Transaction txn, int workoutId) async {
  final finishedTimeData = await txn.rawQuery(
    '''
          SELECT finished_at
          FROM workout_sessions
          WHERE id = ?
          ''',
    [workoutId],
  );

  if (finishedTimeData.isEmpty ||
      finishedTimeData.first['finished_at'] == null) {
    throw Exception('Cannot fetch time of completion');
  }

  await txn.rawDelete(
    '''
          DELETE FROM workout_sessions
          WHERE id = ?
          ''',
    [workoutId],
  );

  final finishedTime = DateTime.fromMillisecondsSinceEpoch(
    (finishedTimeData.first['finished_at'] as int) * 1000,
  );
  final (startSeconds, endSeconds) = _secondsInterval(finishedTime);

  final otherWorkoutsData = await txn.rawQuery(
    '''
    SELECT id
    FROM workout_sessions
    WHERE finished_at >= ? AND finished_at < ?
    ''',
    [startSeconds, endSeconds],
  );

  return (
    finishedTime: finishedTime,
    hasAnotherWorkoutOnSameDay: otherWorkoutsData.isNotEmpty,
  );
}

(int, int) _secondsInterval(DateTime date) {
  final startOfDay = DateTime(date.year, date.month, date.day);
  final startOfNextDay = DateTime(date.year, date.month, date.day + 1);

  final startSeconds = startOfDay.millisecondsSinceEpoch ~/ 1000;
  final endSeconds = startOfNextDay.millisecondsSinceEpoch ~/ 1000;

  return (startSeconds, endSeconds);
}
