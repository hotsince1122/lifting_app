import 'dart:async';

import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/view_model/last_workout_completed_card_view_data.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:riverpod/riverpod.dart';

Future<LastWorkoutCompletedCardViewData?> _loadLastWorkout() async {
  final db = await AppDatabase.getDatabase();

  final workoutData = await db.rawQuery(
    '''
    SELECT ws.workout_name AS workoutName,
      ws.duration_seconds AS workoutDuration,
      ws.id AS lastWorkoutId
    FROM workout_sessions ws
    WHERE ws.status = ?
      AND ws.finished_at IS NOT NULL
    ORDER BY ws.finished_at DESC
    LIMIT 1
    ''',
    [WorkoutSessionStatuses.completedStatus],
  );

  if (workoutData.isEmpty) return null;

  final row = workoutData.first;
  final workoutName = row['workoutName'] as String;
  final workoutDuration = row['workoutDuration'] as int;
  final lastWorkoutId = row['lastWorkoutId'] as int;

  final exerciseCountData = await db.rawQuery(
    '''
    SELECT COUNT(DISTINCT ex_id) AS nrOfExercises
    FROM logged_sets
    WHERE session_id = ?
    ''',
    [lastWorkoutId],
  );

  final nrOfExercises = exerciseCountData.first['nrOfExercises'] as int;

  return LastWorkoutCompletedCardViewData(
    workoutName: workoutName,
    nrOfExercises: nrOfExercises,
    workoutDuration: workoutDuration,
  );
}

final lastWorkoutCompletedProvider =
    AsyncNotifierProvider<
      LastWorkoutCompletedNotifier,
      LastWorkoutCompletedCardViewData?
    >(LastWorkoutCompletedNotifier.new);

class LastWorkoutCompletedNotifier
    extends AsyncNotifier<LastWorkoutCompletedCardViewData?> {
  @override
  FutureOr<LastWorkoutCompletedCardViewData?> build() {
    ref.watch(activeSessionLifecycleProvider);
    return _loadLastWorkout();
  }
}
