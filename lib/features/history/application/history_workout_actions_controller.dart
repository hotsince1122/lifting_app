import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/next_session_preview_provider.dart';
import 'package:lifting_tracker_app/features/workouts/application/workout_name_controller.dart';
import 'package:lifting_tracker_app/features/history/application/history_months_provider.dart';
import 'package:lifting_tracker_app/features/history/data/workout_history_commands.dart'
    as commands;

final historyWorkoutActionsProvider =
    AsyncNotifierProvider<HistoryWorkoutActionsController, void>(
      HistoryWorkoutActionsController.new,
    );

class HistoryWorkoutActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> clearActiveSessionSets(int workoutSessionId) async {
    await commands.clearActiveSessionSets(workoutSessionId);

    ref.invalidate(workoutSessionExercisesProvider(workoutSessionId));
  }

  Future<void> saveEditedWorkout(
    int workoutSessionId, {
    required String workoutName,
  }) async {
    final normalizedWorkoutName = normalizeWorkoutName(workoutName);

    await commands.saveEditedWorkout(workoutSessionId, normalizedWorkoutName);

    ref.invalidate(historyMonthsProvider);
    ref.invalidate(workoutNameProvider(workoutSessionId));
    ref.invalidate(workoutSessionExercisesProvider(workoutSessionId));
  }

  Future<void> deleteWorkout(int workoutId) async {
    final deletionResult = await commands.deleteWorkout(workoutId);

    ref.invalidate(historyMonthsProvider);
    ref.invalidate(nextSessionPreviewProvider);

    final didHandleProgressRollback = await ref
        .read(weeklyWorkoutProgressProvider.notifier)
        .rollbackProgressIfRequired(
          deletionResult.finishedTime,
          hasAnotherWorkoutOnSameDay: deletionResult.hasAnotherWorkoutOnSameDay,
        );

    if (!didHandleProgressRollback) {
      throw Exception('Rollback is required.');
    }
  }
}
