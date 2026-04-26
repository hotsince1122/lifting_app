import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/add_sets_or_exercises.dart';
import 'package:lifting_tracker_app/data/queries/interact_with_active_session/delete_sets_or_exercises.dart';
import 'package:lifting_tracker_app/data/queries/populate_active_sessions_table.dart';
import 'package:lifting_tracker_app/data/queries/save_progress.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/update_state_aux_fuctions.dart';

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

  Future<void> removeSetFromExercise(
    String exerciseId,
    int exerciseOrderIndex,
    int setIndex,
  ) async {
    final didSucceed = await removeSetFromExerciseDb(
      exerciseId,
      exerciseOrderIndex,
      setIndex,
      workoutSessionId,
    );

    final currentState = state.value;

    if (currentState != null && didSucceed) {
      state = deleteExerciseSetFromState(currentState, exerciseId, exerciseOrderIndex, setIndex);
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

  Future<void> saveCurrentSessionProgress () async {
    if (state.value == null) return;

    await saveCurrentSessionProgressDb(state.value!, workoutSessionId);
  }
}
