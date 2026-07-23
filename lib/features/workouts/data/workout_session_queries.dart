import 'package:sqflite/sqflite.dart';

Future<String?> loadWorkoutNameFromWorkoutID(
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