import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:sqflite/sqflite.dart';

bool _readSqliteBool(Object? value) => value == 1 || value == true;

Future<int> loadNextExerciseOrderIndex(
  DatabaseExecutor db,
  int workoutSessionId,
) async {
  final data = await db.rawQuery(
    '''
    SELECT COALESCE(MAX(exercise_order_index) + 1, 0) AS nextExerciseOrderIndex
    FROM active_session_sets
    WHERE workout_session_id = ?
    ''',
    [workoutSessionId],
  );

  return data.first['nextExerciseOrderIndex'] as int;
}

Future<int> loadNextExerciseOccurrenceIndex(
  DatabaseExecutor db,
  int workoutSessionId,
  String exerciseId
) async {
  final data = await db.rawQuery(
    '''
    SELECT COALESCE(MAX(exercise_occurrence_index) + 1, 0) AS nextExerciseOccurrenceIndex
    FROM active_session_sets
    WHERE workout_session_id = ?
      AND exercise_id = ?
    ''',
    [workoutSessionId, exerciseId],
  );

  return data.first['nextExerciseOccurrenceIndex'] as int;
}

Future<List<TrainingSet>> loadActiveSessionSetsForExercise(
  DatabaseExecutor db,
  int workoutSessionId,
  String exerciseId,
  int exerciseOrderIndex,
) async {
  final data = await db.rawQuery(
    '''
    SELECT id AS activeSessionSetId,
      set_index AS setIndex,
      is_warmup AS isWarmup,
      hint_weight AS hintWeight,
      hint_repetitions AS hintRepetitions,
      hint_notes AS hintNotes,
      actual_weight AS actualWeight,
      actual_repetitions AS actualRepetitions,
      actual_notes AS actualNotes
    FROM active_session_sets
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_order_index = ?
    ORDER BY set_index
    ''',
    [workoutSessionId, exerciseId, exerciseOrderIndex],
  );

  return data
      .map(
        (set) => TrainingSet(
          activeSessionSetId: set['activeSessionSetId'] as int,
          setIndex: set['setIndex'] as int,
          isWarmup: _readSqliteBool(set['isWarmup']),
          hintWeight: (set['hintWeight'] as num).toDouble(),
          hintRepetitions: set['hintRepetitions'] as int,
          hintNotes: set['hintNotes'] as String? ?? '',
          actualWeight: (set['actualWeight'] as num?)?.toDouble(),
          actualRepetitions: set['actualRepetitions'] as int?,
          actualNotes: set['actualNotes'] as String?,
        ),
      )
      .toList();
}

Future<int> loadNextSetIndex(
  DatabaseExecutor db,
  int workoutSessionId,
  int exerciseOrderIndex,
) async {
  final data = await db.rawQuery(
    '''
    SELECT COALESCE(MAX(set_index) + 1, 1) AS nextSetIndex
    FROM active_session_sets
    WHERE workout_session_id = ? AND exercise_order_index = ?
    ''',
    [workoutSessionId, exerciseOrderIndex],
  );

  return data.first['nextSetIndex'] as int;
}

TrainingSet emptySet({int? setIndex}) {
  return TrainingSet(
    setIndex: setIndex,
    isWarmup: false,
    hintRepetitions: 0,
    hintWeight: 0,
    hintNotes: '',
  );
}
