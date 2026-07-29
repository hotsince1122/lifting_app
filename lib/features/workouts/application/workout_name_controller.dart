import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;

const _fallbackWorkoutName = 'Workout';

String normalizeWorkoutName(String workoutName) {
  final trimmedWorkoutName = workoutName.trim();
  return trimmedWorkoutName.isEmpty ? _fallbackWorkoutName : trimmedWorkoutName;
}

final workoutNameProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutNameController, String, int>(WorkoutNameController.new);

class WorkoutNameController extends AsyncNotifier<String> {
  WorkoutNameController(this.workoutId);

  final int workoutId;

  @override
  FutureOr<String> build() async {
    return await queries.loadWorkoutSessionName(workoutId) ?? '';
  }

  void renameDraft(String newName) {
    state = AsyncData(newName);
  }

  Future<void> renameLive(String newName) async {
    renameDraft(newName);

    final normalizedName = normalizeWorkoutName(newName);
    if (normalizedName == _fallbackWorkoutName && newName.trim().isEmpty) {
      return;
    }

    await commands.renameWorkoutSession(workoutId, normalizedName);
  }
}
