import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_exercise_commands.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_set_commands.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_exercise_state_updates.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_commands.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';

final workoutSessionExercisesProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutSessionExercisesController, List<WorkoutExercise>, int>(
      WorkoutSessionExercisesController.new,
    );

class WorkoutSessionExercisesController
    extends AsyncNotifier<List<WorkoutExercise>> {
  WorkoutSessionExercisesController(this.workoutSessionId);

  final int workoutSessionId;

  @override
  FutureOr<List<WorkoutExercise>> build() async {
    final status = await queries.loadWorkoutSessionStatus(workoutSessionId);

    if (status == null || status == WorkoutSessionStatuses.abandonedStatus) {
      return [];
    }

    if (status == WorkoutSessionStatuses.completedStatus) {
      return loadSetsForEdit(workoutSessionId);
    }

    return loadOrCreateWorkoutSessionEditorSets(workoutSessionId);
  }

  Future<void> addExercise(CatalogExercise newExercise) async {
    final exerciseToAddToState = await addNewExerciseToDb(
      workoutSessionId,
      newExercise,
    );

    final currentState = state.value;
    if (currentState == null) return;

    state = addExerciseToState(currentState, exerciseToAddToState);
  }

  Future<void> addSetToExercise(WorkoutExercise exercise) async {
    final setToAddToState = await addSetToExerciseInDb(
      exercise,
      workoutSessionId,
    );

    final currentState = state.value;
    if (currentState == null) return;

    state =
        addExerciseSetToState(currentState, exercise, setToAddToState) ?? state;
  }

  Future<void> deleteExercise(String exerciseId, int exerciseOrderIndex) async {
    await deleteExerciseFromDb(
      exerciseId,
      exerciseOrderIndex,
      workoutSessionId,
    );

    final currentState = state.value;
    if (currentState != null) {
      state = deleteExerciseFromState(
        currentState,
        exerciseId,
        exerciseOrderIndex,
      );
    }
  }

  Future<void> replaceExercise(
    WorkoutExercise oldExercise,
    CatalogExercise newExercise,
  ) async {
    final exerciseOrderIndex = oldExercise.orderIndex;
    final currentState = state.value;

    if (currentState == null ||
        oldExercise.catalogExercise.id == newExercise.id) {
      return;
    }

    final replacement = await replaceExerciseInDb(
      workoutSessionId,
      oldExercise,
      newExercise,
    );

    state = replaceExerciseInState(
      currentState,
      oldExercise.catalogExercise.id,
      exerciseOrderIndex,
      replacement,
    );
  }

  Future<void> removeSetFromExercise(int workoutSessionSetId) async {
    final currentState = state.value;
    if (currentState == null) return;

    WorkoutExercise? exerciseToUpdate;
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
      final exerciseId = exerciseToUpdate.catalogExercise.id;

      await deleteExerciseFromDb(
        exerciseId,
        exerciseOrderIndex,
        workoutSessionId,
      );

      state = deleteExerciseFromState(
        currentState,
        exerciseId,
        exerciseOrderIndex,
      );

      return;
    }

    await removeSetFromExerciseDb(workoutSessionSetId, workoutSessionId);

    state = deleteExerciseSetFromState(currentState, workoutSessionSetId);
  }

  Future<void> saveSetCell(
    int workoutSessionSetId,
    double? weight,
    int? reps,
    String? notes,
    String exerciseId,
    int exerciseOrderIndex,
  ) async {
    await saveSetCellToDb(workoutSessionSetId, weight, reps, notes);

    final currentState = state.value;

    if (currentState != null) {
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
    await toggleSetWarmupInDb(workoutSessionSetId, workoutSessionId);

    final currentState = state.value;

    if (currentState != null) {
      state = toggleSetWarmupInState(currentState, workoutSessionSetId);
    }
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;

    if (currentState == null) return;

    final newState = reorderExercisesInState(currentState, oldIndex, newIndex);
    state = AsyncData(newState);

    try {
      await reorderExercisesInDb(newState, workoutSessionId);
    } catch (_) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
