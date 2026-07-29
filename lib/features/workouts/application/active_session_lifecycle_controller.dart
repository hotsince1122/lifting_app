import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/data/split_day_queries.dart'
    as day_queries;
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_cycle_queries.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;

const _quickWorkoutName = 'Quick Workout';

Future<SplitDay> _loadNextScheduledCycleDay(
  List<String> activeSplitDayIds,
) async {
  final nextCycleIndex = await loadNextCycleIndex(activeSplitDayIds);
  return day_queries.loadSplitDayByOrderIndex(
    activeSplitDayIds,
    nextCycleIndex,
  );
}

final activeSessionLifecycleProvider =
    AsyncNotifierProvider<ActiveSessionLifecycleController, bool>(
      ActiveSessionLifecycleController.new,
    );

class ActiveSessionLifecycleController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return queries.hasActiveWorkoutSession();
  }

  Future<int> startSession() async {
    final activeSplitDaysIds = await day_queries.loadActiveSplitDaysIds();
    final pickedWorkoutDayId = await ref.read(pickedNextSessionProvider.future);

    final isPickedDayInActiveSplit =
        pickedWorkoutDayId != null &&
        activeSplitDaysIds.contains(pickedWorkoutDayId);

    final pickedDay = isPickedDayInActiveSplit
        ? await day_queries.loadSplitDayById(pickedWorkoutDayId)
        : null;

    if (pickedWorkoutDayId != null && pickedDay == null) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }

    final nextDayInCycleDay =
        pickedDay ?? await _loadNextScheduledCycleDay(activeSplitDaysIds);

    final sessionId = await commands.createPlannedWorkoutSession(
      workoutName: nextDayInCycleDay.name,
      splitDayId: nextDayInCycleDay.id,
      cycleIndex: nextDayInCycleDay.orderIndex,
    );

    if (pickedDay != null) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }

    state = AsyncData(true);
    return sessionId;
  }

  Future<int> startQuickWorkout({
    String workoutName = _quickWorkoutName,
  }) async {
    final sessionId = await commands.createQuickWorkoutSession(
      workoutName: workoutName,
    );

    state = AsyncData(true);
    return sessionId;
  }

  Future<int> startRepeatedWorkout(int sourceWorkoutId) async {
    final newWorkoutId = await commands.createRepeatedWorkoutSession(
      sourceWorkoutId,
    );

    state = AsyncData(true);
    return newWorkoutId;
  }

  Future<void> endSession(int workoutSessionId) async {
    final finishedWeekday = DateTime.now().weekday;

    await commands.completeWorkoutSession(workoutSessionId);

    await ref
        .read(weeklyWorkoutProgressProvider.notifier)
        .updateProgress(finishedWeekday);

    state = AsyncData(false);
  }
}
