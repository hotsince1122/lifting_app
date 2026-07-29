import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:sqflite/sqflite.dart';

const _quickWorkoutName = 'Quick Workout';

Future<int> _insertQuickWorkoutSession(
  DatabaseExecutor db, {
  required String workoutName,
}) {
  final trimmedWorkoutName = workoutName.trim();

  return db.rawInsert(
    '''
      INSERT INTO workout_sessions (
        workout_name,
        started_at,
        status
      )
      VALUES (?, ?, ?)
      ''',
    [
      trimmedWorkoutName.isEmpty ? _quickWorkoutName : trimmedWorkoutName,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      WorkoutSessionStatuses.activeStatus,
    ],
  );
}

Future<void> _copyExercisesFromSourceWorkout(
  DatabaseExecutor db,
  int sourceWorkoutId,
  int newWorkoutId,
) async {
  final exerciseData = await db.rawQuery(
    '''
      SELECT ls.id AS setId,
        ls.ex_id AS exerciseId,
        ls.weight,
        ls.repetitions,
        ls.notes,
        ls.set_index AS setIndex,
        ls.is_warmup AS isWarmup,
        ls.order_index AS exerciseOrderIndex,
        ls.exercise_occurrence_index AS exerciseOccurrenceIndex,
        e.name AS exerciseName,
        e.muscle_group AS exerciseMuscleGroup
      FROM logged_sets ls
      JOIN exercises e ON e.id = ls.ex_id
      WHERE session_id = ?
      ORDER BY order_index,
        set_index
      ''',
    [sourceWorkoutId],
  );

  final batch = db.batch();

  for (final exercise in exerciseData) {
    batch.insert('active_session_sets', {
      'workout_session_id': newWorkoutId,
      'exercise_id': exercise['exerciseId'] as String,
      'exercise_order_index': exercise['exerciseOrderIndex'] as int,
      'exercise_occurrence_index': exercise['exerciseOccurrenceIndex'] as int,
      'set_index': exercise['setIndex'] as int,
      'hint_weight': (exercise['weight'] as num).toDouble(),
      'hint_repetitions': exercise['repetitions'] as int,
      'hint_notes': exercise['notes'] as String? ?? '',
      'is_warmup': exercise['isWarmup'] as int,
    });
  }

  await batch.commit(noResult: true);
}

Future<void> renameWorkoutSession(
  int workoutSessionId,
  String workoutName,
) async {
  final db = await AppDatabase.getDatabase();

  final rowsUpdated = await db.rawUpdate(
    '''
      UPDATE workout_sessions
      SET workout_name = ?
      WHERE id = ?
    ''',
    [workoutName, workoutSessionId],
  );

  if (rowsUpdated != 1) {
    throw StateError('The workout session was not found.');
  }
}

Future<int> createPlannedWorkoutSession({
  required String workoutName,
  required String splitDayId,
  required int cycleIndex,
}) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction<int>(
    (txn) => txn.rawInsert(
      '''
        INSERT INTO workout_sessions (
          workout_name,
          day_id,
          started_at,
          cycle_index,
          status
        )
        VALUES (?, ?, ?, ?, ?)
        ''',
      [
        workoutName,
        splitDayId,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        cycleIndex,
        WorkoutSessionStatuses.activeStatus,
      ],
    ),
  );
}

Future<int> createQuickWorkoutSession({required String workoutName}) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction<int>(
    (txn) => _insertQuickWorkoutSession(txn, workoutName: workoutName),
  );
}

Future<int> createRepeatedWorkoutSession(int sourceWorkoutId) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction<int>((txn) async {
    final workoutName = await queries.loadWorkoutNameFromWorkoutId(
      txn,
      sourceWorkoutId,
    );

    if (workoutName == null) {
      throw StateError('The source workout was not found.');
    }

    final newWorkoutId = await _insertQuickWorkoutSession(
      txn,
      workoutName: workoutName,
    );

    await _copyExercisesFromSourceWorkout(txn, sourceWorkoutId, newWorkoutId);

    return newWorkoutId;
  });
}

Future<void> completeWorkoutSession(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    final data = await txn.rawQuery(
      '''
        SELECT started_at
        FROM workout_sessions
        WHERE id = ? AND status = ?
        ''',
      [workoutSessionId, WorkoutSessionStatuses.activeStatus],
    );

    if (data.isEmpty) {
      throw StateError('The active workout session was not found.');
    }

    final workoutStartedAt = data.first['started_at'] as int;
    final setsData = await txn.rawQuery(
      '''
        SELECT exercise_id AS ex_id,
          workout_session_id AS session_id,
          actual_weight AS weight,
          actual_repetitions AS repetitions,
          actual_notes AS notes,
          set_index AS set_index,
          exercise_order_index AS order_index,
          exercise_occurrence_index AS exercise_occurrence_index,
          is_warmup AS is_warmup
        FROM active_session_sets
        WHERE actual_weight IS NOT NULL
          AND actual_repetitions IS NOT NULL
          AND workout_session_id = ?
        ''',
      [workoutSessionId],
    );

    final batch = txn.batch();
    for (final setData in setsData) {
      batch.insert('logged_sets', setData);
    }
    await batch.commit(noResult: true);

    final rowsUpdated = await txn.rawUpdate(
      '''
        UPDATE workout_sessions
        SET finished_at = ?,
            duration_seconds = ?,
            status = ?
        WHERE id = ? AND status = ?
        ''',
      [
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - workoutStartedAt,
        WorkoutSessionStatuses.completedStatus,
        workoutSessionId,
        WorkoutSessionStatuses.activeStatus,
      ],
    );

    if (rowsUpdated != 1) {
      throw StateError('The workout session could not be completed.');
    }
  });
}
