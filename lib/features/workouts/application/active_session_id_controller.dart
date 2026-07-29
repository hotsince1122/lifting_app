import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;

final activeSessionIdProvider =
    AsyncNotifierProvider<ActiveSessionIdController, int?>(
      ActiveSessionIdController.new,
    );

class ActiveSessionIdController extends AsyncNotifier<int?> {
  @override
  FutureOr<int?> build() {
    ref.watch(activeSessionLifecycleProvider);
    return queries.loadActiveWorkoutSessionId();
  }

  Future<bool> checkIfSessionIsQuick() async {
    final workoutSessionId = state.value;
    if (workoutSessionId == null) return false;

    return queries.isWorkoutSessionQuick(workoutSessionId);
  }
}
