import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/read_write_sql_bool.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_queries.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';

Future<TrainingSet> addSetToExerciseInDb(
  WorkoutExercise exercise,
  int workoutSessionId,
) async {
  final exerciseOrderIndex = exercise.orderIndex;
  final exerciseId = exercise.catalogExercise.id;

  final db = await AppDatabase.getDatabase();

  return db.transaction((txn) async {
    final nextSetIndex = await loadNextSetIndex(
      txn,
      workoutSessionId,
      exerciseOrderIndex,
    );
    final lastCompletedWorkoutId = await loadLastCompletedWorkoutIdForSameDay(
      txn,
      workoutSessionId,
    );

    TrainingSet? setToInsert;

    final occurrenceIndex = await loadExerciseOccurrenceIndex(
      txn,
      workoutSessionId,
      exerciseId,
      exerciseOrderIndex,
    );

    if (occurrenceIndex == null) {
      throw StateError('The exercise was not found in this workout.');
    }

    if (lastCompletedWorkoutId != null) {
      final dataPreviousWorkoutSet = await txn.rawQuery(
        '''
        SELECT weight AS hintWeight,
          repetitions AS hintRepetitions,
          notes AS hintNotes,
          is_warmup AS isWarmup
        FROM logged_sets
        WHERE session_id = ? AND ex_id = ? AND exercise_occurrence_index = ? AND set_index = ?
        LIMIT 1
        ''',
        [lastCompletedWorkoutId, exerciseId, occurrenceIndex, nextSetIndex],
      );

      if (dataPreviousWorkoutSet.isNotEmpty) {
        final set = dataPreviousWorkoutSet.first;
        setToInsert = TrainingSet(
          setIndex: nextSetIndex,
          hintWeight: (set['hintWeight'] as num).toDouble(),
          hintRepetitions: set['hintRepetitions'] as int,
          hintNotes: set['hintNotes'] as String? ?? '',
          isWarmup: readSqliteBool(set['isWarmup']),
        );
      }
    }

    setToInsert ??= TrainingSet.empty(setIndex: nextSetIndex);

    final workoutSessionSetId = await txn.insert('active_session_sets', {
      'workout_session_id': workoutSessionId,
      'exercise_id': exerciseId,
      'exercise_order_index': exerciseOrderIndex,
      'exercise_occurrence_index': occurrenceIndex,
      'set_index': setToInsert.setIndex ?? nextSetIndex,
      'is_warmup': writeSqliteBool(setToInsert.isWarmup),
      'hint_weight': setToInsert.hintWeight,
      'hint_repetitions': setToInsert.hintRepetitions,
      'hint_notes': setToInsert.hintNotes,
    });

    return setToInsert.copyWith(workoutSessionSetId: workoutSessionSetId);
  });
}

Future<void> removeSetFromExerciseDb(
  int workoutSessionSetId,
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    final setData = await txn.rawQuery(
      '''
      SELECT exercise_id,
        exercise_order_index,
        set_index
      FROM active_session_sets
      WHERE id = ?
        AND workout_session_id = ?
      LIMIT 1
      ''',
      [workoutSessionSetId, workoutSessionId],
    );

    if (setData.isEmpty) {
      throw StateError('The set was not found in this workout.');
    }

    final exerciseId = setData.first['exercise_id'] as String;
    final exerciseOrderIndex = setData.first['exercise_order_index'] as int;
    final setIndex = setData.first['set_index'] as int;

    final rowsDeleted = await txn.rawDelete(
      '''
      DELETE FROM active_session_sets
      WHERE id = ?
        AND workout_session_id = ?
      ''',
      [workoutSessionSetId, workoutSessionId],
    );

    if (rowsDeleted != 1) {
      throw StateError('The set could not be deleted.');
    }

    await txn.rawUpdate(
      '''
      UPDATE active_session_sets
      SET set_index = -set_index
      WHERE workout_session_id = ?
        AND exercise_id = ?
        AND exercise_order_index = ?
        AND set_index > ?
      ''',
      [workoutSessionId, exerciseId, exerciseOrderIndex, setIndex],
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
      [workoutSessionId, exerciseId, exerciseOrderIndex],
    );
  });
}

Future<void> toggleSetWarmupInDb(
  int workoutSessionSetId,
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  final rowsUpdated = await db.transaction((txn) {
    return txn.rawUpdate(
      '''
          UPDATE active_session_sets
          SET is_warmup = CASE
            WHEN is_warmup = 0 THEN 1
            WHEN is_warmup = 1 THEN 0
          END
          WHERE id = ?
            AND workout_session_id = ?
          ''',
      [workoutSessionSetId, workoutSessionId],
    );
  });

  if (rowsUpdated != 1) {
    throw StateError('The set was not found in this workout.');
  }
}

Future<void> fillMissingWorkoutSessionSetsFromHints(
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawUpdate(
      '''
        UPDATE active_session_sets
        SET actual_weight = COALESCE(actual_weight, hint_weight),
            actual_repetitions = COALESCE(
              actual_repetitions,
              hint_repetitions
            ),
            actual_notes = COALESCE(actual_notes, hint_notes)
        WHERE workout_session_id = ?
          AND (actual_weight IS NULL OR actual_repetitions IS NULL)
        ''',
      [workoutSessionId],
    );
  });
}

Future<void> saveSetCellToDb(
  int workoutSessionSetId,
  double? weight,
  int? reps,
  String? notes,
) async {
  final db = await AppDatabase.getDatabase();

  final rowsUpdated = await db.transaction((txn) {
    return txn.rawUpdate(
      '''
      UPDATE active_session_sets
      SET actual_weight = ?,
        actual_repetitions = ?,
        actual_notes = ?
      WHERE id = ?
      ''',
      [weight, reps, notes, workoutSessionSetId],
    );
  });

  if (rowsUpdated != 1) {
    throw StateError('The set was not found in this workout.');
  }
}
