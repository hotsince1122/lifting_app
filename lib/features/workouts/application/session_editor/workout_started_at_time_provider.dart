import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart';

final workoutStartedAtProvider = FutureProvider.family
    .autoDispose<DateTime, int>((ref, workoutSessionId) async {
      return loadWorkoutStartedAt(workoutSessionId);
    });
