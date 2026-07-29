import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/data/planned_exercises_commands.dart'
    as plan_commands;
import 'package:lifting_tracker_app/features/plans/data/planned_exercises_queries.dart'
    as plan_queries;
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as session_queries;
import 'package:lifting_tracker_app/features/workouts/data/workout_set_commands.dart'
    as set_commands;

final workoutEditorCleanUpActionsProvider =
    AsyncNotifierProvider<WorkoutEditorCleanUpActionsController, void>(
      WorkoutEditorCleanUpActionsController.new,
    );

class WorkoutEditorCleanUpActionsController extends AsyncNotifier<void> {
  @override
  void build() {
    return;
  }

  Future<bool> checkIfAnySetEmpty(int workoutSessionId) async {
    return session_queries.hasIncompleteWorkoutSessionSet(workoutSessionId);
  }

  Future<bool> checkIfUserModifiedExercisesPlanned(int workoutSessionId) async {
    final dayId = await session_queries.loadWorkoutSessionDayId(
      workoutSessionId,
    );
    if (dayId == null) return false;

    final exercisesPlanned = await plan_queries.loadPlannedExercises(dayId);
    final exercisesExecutedIds = await session_queries.loadExecutedExerciseIds(
      workoutSessionId,
    );

    if (exercisesPlanned.length != exercisesExecutedIds.length) return true;

    for (int i = 0; i < exercisesExecutedIds.length; i++) {
      if (exercisesExecutedIds[i] != exercisesPlanned[i].catalogExercise.id) {
        return true;
      }
    }

    return false;
  }

  Future<void> saveEmptySetsWithHints(int workoutSessionId) async {
    await set_commands.fillMissingWorkoutSessionSetsFromHints(workoutSessionId);
  }

  Future<void> updateCurrentPlan(int workoutSessionId) async {
    final exerciseIds = await session_queries.loadExecutedExerciseIds(
      workoutSessionId,
    );
    final dayId = await session_queries.loadWorkoutSessionDayId(
      workoutSessionId,
    );

    if (dayId == null) return;

    await plan_commands.replacePlannedExercises(dayId, exerciseIds);
  }
}
