import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/aux_functions_active_session.dart';
import 'package:lifting_tracker_app/data/queries/populate_active_sessions_table.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:sqflite/sqflite.dart';

bool _readSqliteBool(Object? value) => value == 1 || value == true;

int _writeSqliteBool(bool? value) => value == true ? 1 : 0;

Future<Exercise?> addNewExerciseToDb(
  int workoutSessionId,
  Exercise newExercise,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    final exerciseToAddToUI = await db.transaction((txn) async {
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
                isWarmup: _readSqliteBool(set['isWarmup']),
                hintWeight: (set['hintWeight'] as num).toDouble(),
                hintRepetitions: set['hintRepetitions'] as int,
                hintNotes: set['hintNotes'] as String? ?? '',
              ),
            )
            .toList();
      }

      if (setsToInsert.isEmpty) {
        setsToInsert = [emptySet(setIndex: 1)];
      }

      await populateActiveSessionSets(
        [
          Exercise(
            id: newExercise.id,
            name: newExercise.name,
            muscleGroup: newExercise.muscleGroup,
            orderIndex: nextExerciseOrderIndex,
            sets: setsToInsert,
          ),
        ],
        txn,
        workoutSessionId,
        exerciseOccurrenceIndexOverride: nextExerciseOccurrenceIndex,
      );

      final activeSets = await loadActiveSessionSetsForExercise(
        txn,
        workoutSessionId,
        newExercise.id,
        nextExerciseOrderIndex,
      );

      return Exercise(
        id: newExercise.id,
        name: newExercise.name,
        muscleGroup: newExercise.muscleGroup,
        orderIndex: nextExerciseOrderIndex,
        sets: activeSets,
      );
    });

    return exerciseToAddToUI;
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}

Future<TrainingSet?> addSetToExerciseInDb(
  Exercise exercise,
  int workoutSessionId,
) async {
  final exerciseOrderIndex = exercise.orderIndex;
  if (exerciseOrderIndex == null) return null;

  final db = await AppDatabases.getDatabase();

  try {
    final setToInsertUI = await db.transaction((txn) async {
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

      final occurrenceIndex = await retriveExerciseOccurrenceIndex(
        txn,
        exercise.id,
        exerciseOrderIndex,
        workoutSessionId,
      );

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
          [lastCompletedWorkoutId, exercise.id, occurrenceIndex, nextSetIndex],
        );

        if (dataPreviousWorkoutSet.isNotEmpty) {
          final set = dataPreviousWorkoutSet.first;
          setToInsert = TrainingSet(
            setIndex: nextSetIndex,
            hintWeight: (set['hintWeight'] as num).toDouble(),
            hintRepetitions: set['hintRepetitions'] as int,
            hintNotes: set['hintNotes'] as String? ?? '',
            isWarmup: _readSqliteBool(set['isWarmup'])
          );
        }
      }

      setToInsert ??= emptySet(setIndex: nextSetIndex);

      final activeSessionSetId = await txn.insert('active_session_sets', {
        'workout_session_id': workoutSessionId,
        'exercise_id': exercise.id,
        'exercise_order_index': exerciseOrderIndex,
        'exercise_occurrence_index': occurrenceIndex,
        'set_index': setToInsert.setIndex ?? nextSetIndex,
        'is_warmup': _writeSqliteBool(setToInsert.isWarmup),
        'hint_weight': setToInsert.hintWeight,
        'hint_repetitions': setToInsert.hintRepetitions,
        'hint_notes': setToInsert.hintNotes,
      });

      return TrainingSet(
        activeSessionSetId: activeSessionSetId,
        setIndex: setToInsert.setIndex,
        isWarmup: setToInsert.isWarmup,
        hintRepetitions: setToInsert.hintRepetitions,
        hintWeight: setToInsert.hintWeight,
        hintNotes: setToInsert.hintNotes,
        actualRepetitions: setToInsert.actualRepetitions,
        actualWeight: setToInsert.actualWeight,
        actualNotes: setToInsert.actualNotes,
      );
    });

    return setToInsertUI;
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}

Future<int> retriveExerciseOccurrenceIndex(
  Transaction db,
  String exerciseId,
  int exerciseOrderIndex,
  int workoutSessionId,
) async {
  final data = await db.rawQuery(
    '''
    SELECT exercise_occurrence_index
    FROM active_session_sets
    WHERE exercise_id = ?
      AND exercise_order_index = ?
      AND workout_session_id = ?
    ''',
    [exerciseId, exerciseOrderIndex, workoutSessionId],
  );

  return data[0]['exercise_occurrence_index'] as int;
}
