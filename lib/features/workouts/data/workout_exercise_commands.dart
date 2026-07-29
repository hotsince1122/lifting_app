import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/read_write_sql_bool.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_commands.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_queries.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:sqflite/sqflite.dart';

Future<WorkoutExercise> addNewExerciseToDb(
  int workoutSessionId,
  CatalogExercise newExercise,
) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction((txn) async {
    final nextExerciseOccurrenceIndex = await loadNextExerciseOccurrenceIndex(
      txn,
      workoutSessionId,
      newExercise.id,
    );
    final nextExerciseOrderIndex = await loadNextExerciseOrderIndex(
      txn,
      workoutSessionId,
    );
    final lastCompletedWorkoutId = await loadLastCompletedWorkoutIdForSameDay(
      txn,
      workoutSessionId,
    );

    List<TrainingSet> setsToInsert = [];

    if (lastCompletedWorkoutId != null) {
      final dataPreviousWorkoutSets = await txn.rawQuery(
        '''
        SELECT set_index AS setIndex,
          is_warmup AS isWarmup,
          weight AS hintWeight,
          repetitions AS hintRepetitions,
          notes AS hintNotes
        FROM logged_sets
        WHERE session_id = ? AND ex_id = ? AND exercise_occurrence_index = ?
        ORDER BY set_index
        ''',
        [lastCompletedWorkoutId, newExercise.id, nextExerciseOccurrenceIndex],
      );

      setsToInsert = dataPreviousWorkoutSets
          .map(
            (set) => TrainingSet(
              setIndex: set['setIndex'] as int,
              isWarmup: readSqliteBool(set['isWarmup']),
              hintWeight: (set['hintWeight'] as num).toDouble(),
              hintRepetitions: set['hintRepetitions'] as int,
              hintNotes: set['hintNotes'] as String? ?? '',
            ),
          )
          .toList();
    }

    if (setsToInsert.isEmpty) {
      setsToInsert = [TrainingSet.empty(setIndex: 1)];
    }

    await populateWorkoutSessionSets(
      [
        WorkoutExercise(
          catalogExercise: newExercise,
          orderIndex: nextExerciseOrderIndex,
          sets: setsToInsert,
        ),
      ],
      txn,
      workoutSessionId,
      exerciseOccurrenceIndexOverride: nextExerciseOccurrenceIndex,
    );

    final workoutSets = await loadWorkoutSessionSetsForExercise(
      txn,
      workoutSessionId,
      newExercise.id,
      nextExerciseOrderIndex,
    );

    return WorkoutExercise(
      catalogExercise: newExercise,
      orderIndex: nextExerciseOrderIndex,
      sets: workoutSets,
    );
  });
}

Future<WorkoutExercise> replaceExerciseInDb(
  int workoutSessionId,
  WorkoutExercise oldExercise,
  CatalogExercise newExercise,
) async {
  final exerciseOrderIndex = oldExercise.orderIndex;
  if (oldExercise.sets.isEmpty) {
    throw StateError('The exercise has no sets to replace.');
  }

  final oldExerciseId = oldExercise.catalogExercise.id;

  final workoutSessionSetIds = <int>[];
  for (final set in oldExercise.sets) {
    final workoutSessionSetId = set.workoutSessionSetId;
    if (workoutSessionSetId == null) {
      throw StateError('A workout set has not been saved yet.');
    }

    workoutSessionSetIds.add(workoutSessionSetId);
  }

  final db = await AppDatabase.getDatabase();

  return db.transaction((txn) async {
    final oldOccurrenceIndex = await loadExerciseOccurrenceIndex(
      txn,
      workoutSessionId,
      oldExerciseId,
      exerciseOrderIndex,
    );

    if (oldOccurrenceIndex == null) {
      throw StateError('The exercise was not found in this workout.');
    }

    final newOccurrenceIndex = await loadNextExerciseOccurrenceIndex(
      txn,
      workoutSessionId,
      newExercise.id,
    );
    final lastCompletedWorkoutId = await loadLastCompletedWorkoutIdForSameDay(
      txn,
      workoutSessionId,
    );
    final setsToUse = await _loadReplacementSets(
      txn,
      lastCompletedWorkoutId,
      newExercise.id,
      newOccurrenceIndex,
      oldExercise.sets.length,
    );

    for (var i = 0; i < workoutSessionSetIds.length; i++) {
      final setToUse = setsToUse[i];
      final rowsUpdated = await txn.update(
        'active_session_sets',
        {
          'exercise_id': newExercise.id,
          'exercise_occurrence_index': newOccurrenceIndex,
          'set_index': setToUse.setIndex ?? i + 1,
          'is_warmup': writeSqliteBool(setToUse.isWarmup),
          'hint_weight': setToUse.hintWeight,
          'hint_repetitions': setToUse.hintRepetitions,
          'hint_notes': setToUse.hintNotes,
          'actual_weight': null,
          'actual_repetitions': null,
          'actual_notes': null,
        },
        where: 'id = ? AND workout_session_id = ?',
        whereArgs: [workoutSessionSetIds[i], workoutSessionId],
      );

      if (rowsUpdated != 1) {
        throw StateError('Some workout session sets were not replaced.');
      }
    }

    await _compactExerciseOccurrenceIndexes(
      txn,
      workoutSessionId,
      oldExerciseId,
      oldOccurrenceIndex,
    );

    final workoutSets = await loadWorkoutSessionSetsForExercise(
      txn,
      workoutSessionId,
      newExercise.id,
      exerciseOrderIndex,
    );

    return oldExercise.copyWith(
      catalogExercise: newExercise,
      sets: workoutSets,
    );
  });
}

Future<List<TrainingSet>> _loadReplacementSets(
  DatabaseExecutor db,
  int? lastCompletedWorkoutId,
  String exerciseId,
  int exerciseOccurrenceIndex,
  int setCount,
) async {
  final replacementSets = List.generate(
    setCount,
    (i) => TrainingSet.empty(setIndex: i + 1),
  );

  if (lastCompletedWorkoutId == null) return replacementSets;

  final dataPreviousWorkoutSets = await db.rawQuery(
    '''
    SELECT set_index AS setIndex,
      is_warmup AS isWarmup,
      weight AS hintWeight,
      repetitions AS hintRepetitions,
      notes AS hintNotes
    FROM logged_sets
    WHERE session_id = ?
      AND ex_id = ?
      AND exercise_occurrence_index = ?
      AND set_index <= ?
    ORDER BY set_index
    ''',
    [lastCompletedWorkoutId, exerciseId, exerciseOccurrenceIndex, setCount],
  );

  for (final set in dataPreviousWorkoutSets) {
    final setIndex = set['setIndex'] as int;
    if (setIndex < 1 || setIndex > setCount) continue;

    replacementSets[setIndex - 1] = TrainingSet(
      setIndex: setIndex,
      isWarmup: readSqliteBool(set['isWarmup']),
      hintWeight: (set['hintWeight'] as num).toDouble(),
      hintRepetitions: set['hintRepetitions'] as int,
      hintNotes: set['hintNotes'] as String? ?? '',
    );
  }

  return replacementSets;
}

Future<void> _compactExerciseOccurrenceIndexes(
  DatabaseExecutor db,
  int workoutSessionId,
  String exerciseId,
  int replacedExerciseOccurrenceIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_occurrence_index = exercise_occurrence_index - 1
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_occurrence_index > ?
    ''',
    [workoutSessionId, exerciseId, replacedExerciseOccurrenceIndex],
  );
}

Future<void> deleteExerciseFromDb(
  String exerciseId,
  int exerciseOrderIndex,
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    final exerciseOccurrenceIndex = await loadExerciseOccurrenceIndex(
      txn,
      workoutSessionId,
      exerciseId,
      exerciseOrderIndex,
    );

    if (exerciseOccurrenceIndex == null) {
      throw StateError('The exercise was not found in this workout.');
    }

    final rowsDeleted = await _deleteExerciseRows(
      txn,
      workoutSessionId,
      exerciseId,
      exerciseOrderIndex,
    );

    if (rowsDeleted < 1) {
      throw StateError('The exercise could not be deleted.');
    }

    await _compactExerciseOrderIndexes(
      txn,
      workoutSessionId,
      exerciseOrderIndex,
    );

    await _compactExerciseOccurrenceIndexesAfterDeletion(
      txn,
      workoutSessionId,
      exerciseId,
      exerciseOccurrenceIndex,
    );
  });
}

Future<int> _deleteExerciseRows(
  DatabaseExecutor db,
  int workoutSessionId,
  String exerciseId,
  int exerciseOrderIndex,
) {
  return db.rawDelete(
    '''
    DELETE FROM active_session_sets
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_order_index = ?
    ''',
    [workoutSessionId, exerciseId, exerciseOrderIndex],
  );
}

Future<void> _compactExerciseOrderIndexes(
  DatabaseExecutor db,
  int workoutSessionId,
  int deletedExerciseOrderIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index
    WHERE workout_session_id = ?
      AND exercise_order_index > ?
    ''',
    [workoutSessionId, deletedExerciseOrderIndex],
  );

  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_order_index = -exercise_order_index - 1
    WHERE workout_session_id = ?
      AND exercise_order_index < 0
    ''',
    [workoutSessionId],
  );
}

Future<void> _compactExerciseOccurrenceIndexesAfterDeletion(
  DatabaseExecutor db,
  int workoutSessionId,
  String exerciseId,
  int deletedExerciseOccurrenceIndex,
) async {
  await db.rawUpdate(
    '''
    UPDATE active_session_sets
    SET exercise_occurrence_index = exercise_occurrence_index - 1
    WHERE workout_session_id = ?
      AND exercise_id = ?
      AND exercise_occurrence_index > ?
    ''',
    [workoutSessionId, exerciseId, deletedExerciseOccurrenceIndex],
  );
}

Future<void> reorderExercisesInDb(
  List<WorkoutExercise> reorderedExercises,
  int workoutSessionId,
) async {
  final setUpdates = <({int workoutSessionSetId, int orderIndex})>[];

  for (final exercise in reorderedExercises) {
    final orderIndex = exercise.orderIndex;

    for (final set in exercise.sets) {
      final workoutSessionSetId = set.workoutSessionSetId;
      if (workoutSessionSetId == null) {
        throw StateError('A workout set has not been saved yet.');
      }

      setUpdates.add((
        workoutSessionSetId: workoutSessionSetId,
        orderIndex: orderIndex,
      ));
    }
  }

  if (setUpdates.isEmpty) return;

  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
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
          update.workoutSessionSetId,
          workoutSessionId,
        ],
      );
    }

    if (updatedRows != setUpdates.length) {
      throw StateError('Some workout session sets were not found.');
    }

    final rowsMovedToFinalIndexes = await txn.rawUpdate(
      '''
        UPDATE active_session_sets
        SET exercise_order_index = -exercise_order_index - 1
        WHERE workout_session_id = ?
          AND exercise_order_index < 0
        ''',
      [workoutSessionId],
    );

    if (rowsMovedToFinalIndexes != setUpdates.length) {
      throw StateError('Some workout session sets were not finalized.');
    }
  });
}
