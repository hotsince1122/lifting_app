import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/data/add_sets_or_exercises.dart';
import 'package:lifting_tracker_app/features/workouts/data/replace_workout_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_set_commands.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:lifting_tracker_app/features/workouts/application/exercise_and_sets/session_editor/workout_exercise_state_updates.dart';
import 'package:lifting_tracker_app/features/workouts/data/delete_sets_or_exercises.dart';
import 'package:lifting_tracker_app/features/workouts/data/exercise_in_a_workout_actions.dart';
import 'package:lifting_tracker_app/features/workouts/data/populate_workout_session_sets.dart';
import 'package:lifting_tracker_app/features/exercises/domain/exercise.dart';

FutureOr<String?> _checkWorkoutStatus(int workoutSessionId) async {
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

  final row = data.first;
  return row['status'] as String;
}

final workoutSessionExercisesProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutSessionExercisesController, List<Exercise>, int>(
      WorkoutSessionExercisesController.new,
    );

class WorkoutSessionExercisesController extends AsyncNotifier<List<Exercise>> {
  WorkoutSessionExercisesController(this.workoutSessionId);

  final int workoutSessionId;

  @override
  FutureOr<List<Exercise>> build() async {
    final status = await _checkWorkoutStatus(workoutSessionId);

    if (status == null || status == WorkoutSessionStatuses.abandonedStatus) {
      return [];
    }

    if (status == WorkoutSessionStatuses.completedStatus) {
      return loadSetsForEdit(workoutSessionId);
    }

    return loadOrCreateWorkoutSessionEditorSets(workoutSessionId);
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

    state =
        addExerciseSetToState(currentState, exercise, setToAddToState) ?? state;
  }

  Future<void> deleteExercise(String exerciseId, int exerciseOrderIndex) async {
    final didSucceed = await deleteExerciseFromDb(
      exerciseId,
      exerciseOrderIndex,
      workoutSessionId,
    );

    final currentState = state.value;
    if (didSucceed && currentState != null) {
      state = deleteExerciseFromState(
        currentState,
        exerciseId,
        exerciseOrderIndex,
      );
    }
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

  Future<void> removeSetFromExercise(int workoutSessionSetId) async {
    final currentState = state.value;
    if (currentState == null) return;

    Exercise? exerciseToUpdate;
    for (final exercise in currentState) {
      final containsSet = exercise.sets.any(
        (set) => set.workoutSessionSetId == workoutSessionSetId,
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
      workoutSessionSetId,
      workoutSessionId,
    );

    if (didSucceed) {
      state = deleteExerciseSetFromState(currentState, workoutSessionSetId);
    }
  }

  Future<void> saveSetCell(
    int workoutSessionSetId,
    double? weight,
    int? reps,
    String? notes,
    String exerciseId,
    int exerciseOrderIndex,
  ) async {
    final didSucceed = await saveSetCellToDb(
      workoutSessionSetId,
      weight,
      reps,
      notes,
    );

    final currentState = state.value;

    if (currentState != null && didSucceed) {
      state = saveSetCellToState(
        currentState,
        exerciseId,
        exerciseOrderIndex,
        workoutSessionSetId,
        reps,
        weight,
        notes,
      );
    }
  }

  Future<void> toggleSetWarmup(int workoutSessionSetId) async {
    final didSucceed = await toggleSetWarmupInDb(
      workoutSessionSetId,
      workoutSessionId,
    );

    final currentState = state.value;

    if (currentState != null && didSucceed) {
      state = toggleSetWarmupInState(currentState, workoutSessionSetId);
    }
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;

    if (currentState == null) return;

    final newState = reorderExercisesInState(currentState, oldIndex, newIndex);
    state = AsyncData(newState);

    final didSucceed = await reorderExercisesInDb(newState, workoutSessionId);

    if (!didSucceed) state = AsyncData(currentState);
  }
}
