import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:sqflite/sqflite.dart';

typedef WorkoutSessionSummaryRecord = ({
  String workoutName,
  DateTime startedAt,
  DateTime? finishedAt,
  int? durationSeconds,
});

Future<bool> hasActiveWorkoutSession() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT id
      FROM workout_sessions
      WHERE status = ?
      ''',
    [WorkoutSessionStatuses.activeStatus],
  );

  return data.isNotEmpty;
}

Future<int?> loadActiveWorkoutSessionId() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT id
      FROM workout_sessions
      WHERE status = ?
      ORDER BY started_at DESC
      LIMIT 1
      ''',
    [WorkoutSessionStatuses.activeStatus],
  );

  if (data.isEmpty) return null;

  return data.first['id'] as int;
}

Future<bool> isWorkoutSessionQuick(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
      ''',
    [workoutSessionId],
  );

  return data.first['day_id'] == null;
}

Future<String?> loadWorkoutSessionDayId(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
      ''',
    [workoutSessionId],
  );

  if (data.isEmpty) return null;

  return data.first['day_id'] as String?;
}

Future<String?> loadWorkoutSessionStatus(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT status
      FROM workout_sessions
      WHERE id = ?
      ''',
    [workoutSessionId],
  );

  if (data.isEmpty) return null;

  return data.first['status'] as String;
}

Future<bool> hasIncompleteWorkoutSessionSet(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT id
      FROM active_session_sets
      WHERE workout_session_id = ?
        AND (
          actual_weight IS NULL
          OR actual_repetitions IS NULL
        )
      LIMIT 1
      ''',
    [workoutSessionId],
  );

  return data.isNotEmpty;
}

Future<List<String>> loadExecutedExerciseIds(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT exercise_id
      FROM active_session_sets
      WHERE workout_session_id = ?
      GROUP BY exercise_order_index
      ORDER BY exercise_order_index
      ''',
    [workoutSessionId],
  );

  return data.map((row) => row['exercise_id'] as String).toList();
}

Future<String?> loadWorkoutSessionName(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();
  return loadWorkoutNameFromWorkoutId(db, workoutSessionId);
}

Future<WorkoutSessionSummaryRecord?> loadWorkoutSessionSummary(
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery(
    '''
      SELECT workout_name,
        started_at,
        finished_at,
        duration_seconds
      FROM workout_sessions
      WHERE id = ?
      ''',
    [workoutSessionId],
  );

  if (data.isEmpty) return null;

  final row = data.first;
  final finishedAtSeconds = row['finished_at'] as int?;

  return (
    workoutName: row['workout_name'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['started_at'] as int) * 1000,
    ),
    finishedAt: finishedAtSeconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(finishedAtSeconds * 1000),
    durationSeconds: row['duration_seconds'] as int?,
  );
}

Future<String?> loadWorkoutNameFromWorkoutId(
  DatabaseExecutor db,
  int sourceWorkoutId,
) async {
  final data = await db.rawQuery(
    '''
    SELECT workout_name
    FROM workout_sessions
    WHERE id = ?
    ''',
    [sourceWorkoutId],
  );

  if (data.isEmpty) return null;

  return data.first['workout_name'] as String;
}

Future<int?> loadExerciseOccurrenceIndex(
  DatabaseExecutor db,
  int workoutSessionId,
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
    [workoutSessionId, exerciseId, exerciseOrderIndex],
  );

  if (data.isEmpty) return null;

  return data.first['exercise_occurrence_index'] as int;
}
