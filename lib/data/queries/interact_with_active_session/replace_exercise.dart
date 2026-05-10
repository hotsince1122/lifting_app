import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/aux_functions_active_session.dart';
import 'package:lifting_tracker_app/data/queries/populate_active_sessions_table.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:sqflite/sqflite.dart';

bool _readSqliteBool(Object? value) => value == 1 || value == true;

int _writeSqliteBool(bool? value) => value == true ? 1 : 0;

Future<Exercise?> replaceExerciseInDb(
  int workoutSessionId,
  Exercise oldExercise,
  Exercise newExercise,
) async {
  final exerciseOrderIndex = oldExercise.orderIndex;
  if (exerciseOrderIndex == null || oldExercise.sets.isEmpty) return null;

  final activeSessionSetIds = <int>[];
  for (final set in oldExercise.sets) {
    final activeSessionSetId = set.activeSessionSetId;
    if (activeSessionSetId == null) return null;

    activeSessionSetIds.add(activeSessionSetId);
  }

  final db = await AppDatabases.getDatabase();

  try {
    return db.transaction((txn) async {
      final oldOccurrenceIndex = await _loadExerciseOccurrenceIndex(
        txn,
        workoutSessionId,
        oldExercise.id,
        exerciseOrderIndex,
      );

      if (oldOccurrenceIndex == null) return null;

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

      for (var i = 0; i < activeSessionSetIds.length; i++) {
        final setToUse = setsToUse[i];
        final rowsUpdated = await txn.update(
          'active_session_sets',
          {
            'exercise_id': newExercise.id,
            'exercise_occurrence_index': newOccurrenceIndex,
            'set_index': setToUse.setIndex ?? i + 1,
            'is_warmup': _writeSqliteBool(setToUse.isWarmup),
            'hint_weight': setToUse.hintWeight,
            'hint_repetitions': setToUse.hintRepetitions,
            'hint_notes': setToUse.hintNotes,
            'actual_weight': null,
            'actual_repetitions': null,
            'actual_notes': null,
          },
          where: 'id = ? AND workout_session_id = ?',
          whereArgs: [activeSessionSetIds[i], workoutSessionId],
        );

        if (rowsUpdated != 1) {
          throw StateError('Some active session sets were not replaced.');
        }
      }

      await _compactExerciseOccurrenceIndexes(
        txn,
        workoutSessionId,
        oldExercise.id,
        oldOccurrenceIndex,
      );

      final activeSets = await loadActiveSessionSetsForExercise(
        txn,
        workoutSessionId,
        newExercise.id,
        exerciseOrderIndex,
      );

      return newExercise.copyWith(
        orderIndex: exerciseOrderIndex,
        sets: activeSets,
      );
    });
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}

Future<int?> _loadExerciseOccurrenceIndex(
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

Future<List<TrainingSet>> _loadReplacementSets(
  DatabaseExecutor db,
  int? lastCompletedWorkoutId,
  String exerciseId,
  int exerciseOccurrenceIndex,
  int setCount,
) async {
  final replacementSets = List.generate(
    setCount,
    (i) => emptySet(setIndex: i + 1),
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
      isWarmup: _readSqliteBool(set['isWarmup']),
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
