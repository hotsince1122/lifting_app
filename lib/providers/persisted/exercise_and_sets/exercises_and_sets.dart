import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/add_sets_or_exercises.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/delete_sets_or_exercises.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/miscellaneous_funcs.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/replace_exercise.dart';
import 'package:lifting_tracker_app/data/queries/populate_active_sessions_table.dart';
import 'package:lifting_tracker_app/data/queries/save_progress.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/update_state_fuctions.dart';

FutureOr<String?> _checkWorkoutStatus(int workoutSessionId) async {
  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery(
    '''
    SELECT status
    FROM workout_sessions
    WHERE id = ?
    ''',
    [workoutSessionId],
  );

  if (data.isEmpty) return null;

  final row = data.first;
  return row['status'] as String;
}

final exercisesAndSetsProvider =
    AsyncNotifierProvider.family<ExercisesAndSetsProvider, List<Exercise>, int>(
      ExercisesAndSetsProvider.new,
    );

class ExercisesAndSetsProvider extends AsyncNotifier<List<Exercise>> {
  ExercisesAndSetsProvider(this.workoutSessionId);

  final int workoutSessionId;

  @override
  FutureOr<List<Exercise>> build() async {
    final status = await _checkWorkoutStatus(workoutSessionId);

    if (status == null || status == WorkoutSessionStatuses.abandonedStatus) {
      return [];
    }

    return resumeOrStartRepetedWorkout(workoutSessionId);
  }

  Future<void> addExercise(Exercise newExercise) async {
    final exerciseToAddToState = await addNewExerciseToDb(
      workoutSessionId,
      newExercise,
    );

    final currentState = state.value;
    if (exerciseToAddToState == null || currentState == null) return;

    state = addExerciseToState(currentState, exerciseToAddToState);
  }

  Future<void> addSetToExercise(Exercise exercise) async {
    final setToAddToState = await addSetToExerciseInDb(
      exercise,
      workoutSessionId,
    );

    final currentState = state.value;
    if (setToAddToState == null || currentState == null) return;

    state = addExerciseSetToState (currentState, exercise, setToAddToState) ?? state;
  }

  Future<void> deleteExercise(String exerciseId, int exerciseOrderIndex) async {
    final didSucceed = await deleteExerciseFromDb(
      exerciseId,
      exerciseOrderIndex,
      workoutSessionId,
    );

    final currentState = state.value;
    if (didSucceed && currentState != null) state = deleteExerciseFromState(currentState, exerciseId, exerciseOrderIndex);
  }

  Future<void> replaceExercise(
    Exercise oldExercise,
    Exercise newExercise,
  ) async {
    final exerciseOrderIndex = oldExercise.orderIndex;
    final currentState = state.value;

    if (exerciseOrderIndex == null ||
        currentState == null ||
        oldExercise.id == newExercise.id) {
      return;
    }

    final replacement = await replaceExerciseInDb(
      workoutSessionId,
      oldExercise,
      newExercise,
    );

    if (replacement == null) return;

    state = replaceExerciseInState(
      currentState,
      oldExercise.id,
      exerciseOrderIndex,
      replacement,
    );
  }

  Future<void> removeSetFromExercise(
    int activeSessionSetId,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    Exercise? exerciseToUpdate;
    for (final exercise in currentState) {
      final containsSet = exercise.sets.any(
        (set) => set.activeSessionSetId == activeSessionSetId,
      );

      if (containsSet) {
        exerciseToUpdate = exercise;
        break;
      }
    }

    if (exerciseToUpdate == null) return;

    if (exerciseToUpdate.sets.length == 1) {
      final exerciseOrderIndex = exerciseToUpdate.orderIndex;
      if (exerciseOrderIndex == null) return;

      final didSucceed = await deleteExerciseFromDb(
        exerciseToUpdate.id,
        exerciseOrderIndex,
        workoutSessionId,
      );

      if (didSucceed) {
        state = deleteExerciseFromState(
          currentState,
          exerciseToUpdate.id,
          exerciseOrderIndex,
        );
      }

      return;
    }

    final didSucceed = await removeSetFromExerciseDb(
      activeSessionSetId,
      workoutSessionId,
    );

    if (didSucceed) {
      state = deleteExerciseSetFromState(currentState, activeSessionSetId);
    }
  }

  Future<void> saveSetCell( 
    int activeSessionSetId,
    double? weight,
    int? reps,
    String? notes,
    String exerciseId,
    int exerciseOrderIndex,
  ) async {
    final didSucceed = await saveSetCellToDb(
      activeSessionSetId,
      weight,
      reps,
      notes,
    );

    final currentState = state.value;

    if (currentState != null && didSucceed) {
      state = saveSetCellToState(currentState, exerciseId, exerciseOrderIndex, activeSessionSetId, reps, weight, notes);
    }
  }

  Future<void> toggleSetWarmup (int activeSessionSetId) async {
    final didSucceed = await toggleSetWarmupInDb(
      activeSessionSetId,
      workoutSessionId,
    );

    final currentState = state.value;

    if (currentState != null && didSucceed) {
      state = toggleSetWarmupInState(currentState, activeSessionSetId);
    }
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;

    if (currentState == null) return;

    final newState = reorderExercisesInState(currentState, oldIndex, newIndex);
    state = AsyncData(newState);

    final didSucceed = await reorderExercisesInDb(
      newState,
      workoutSessionId,
    );

    if (!didSucceed) state = AsyncData(currentState);
  }
}
