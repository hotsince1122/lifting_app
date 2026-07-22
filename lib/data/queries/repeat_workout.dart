import 'package:sqflite/sqflite.dart';

Future<void> loadExercisesFromSourceWorkoutInDb(
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

  for (final eachExerciseData in exerciseData) {
    batch.insert('active_session_sets', ({
      'workout_session_id': newWorkoutId,
      'exercise_id': eachExerciseData['exerciseId'] as String,
      'exercise_order_index': eachExerciseData['exerciseOrderIndex'] as int,
      'exercise_occurrence_index':
          eachExerciseData['exerciseOccurrenceIndex'] as int,
      'set_index': eachExerciseData['setIndex'] as int,
      'hint_weight': (eachExerciseData['weight'] as num).toDouble(),
      'hint_repetitions': eachExerciseData['repetitions'] as int,
      'hint_notes': eachExerciseData['notes'] as String? ?? '',
      'is_warmup': eachExerciseData['isWarmup'] as int,
    }));
  }

  await batch.commit(noResult: true);
}
