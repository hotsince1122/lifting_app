import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/read_write_sql_bool.dart';
import 'package:lifting_tracker_app/features/workouts/data/populate_workout_session_sets.dart';
import 'package:lifting_tracker_app/features/exercises/domain/exercise.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_queries.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';

Future<Exercise?> addNewExerciseToDb(
  int workoutSessionId,
  Exercise newExercise,
) async {
  final db = await AppDatabase.getDatabase();

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
                isWarmup: readSqliteBool(set['isWarmup']),
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

      await populateWorkoutSessionSets(
        [
          newExercise.copyWith(
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

      return newExercise.copyWith(
        orderIndex: nextExerciseOrderIndex,
        sets: workoutSets,
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

  final db = await AppDatabase.getDatabase();

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

      final occurrenceIndex = await loadExerciseOccurrenceIndex(
        txn,
        workoutSessionId,
        exercise.id,
        exerciseOrderIndex,
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
            isWarmup: readSqliteBool(set['isWarmup']),
          );
        }
      }

      setToInsert ??= emptySet(setIndex: nextSetIndex);

      final workoutSessionSetId = await txn.insert('active_session_sets', {
        'workout_session_id': workoutSessionId,
        'exercise_id': exercise.id,
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

    return setToInsertUI;
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}
