import 'dart:async';

import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/view_model/last_workout_completed_card_vm.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';
import 'package:riverpod/riverpod.dart';

Future<LastWorkoutCompletedCardVm?> _loadLastWorkout() async {
  final db = await AppDatabases.getDatabase();

  final workoutData = await db.rawQuery(
    '''
    SELECT sd.name AS workoutName,
      ws.duration_seconds AS workoutDuration,
      ws.id AS lastWorkoutId
    FROM workout_sessions ws
    JOIN split_days sd ON ws.day_id = sd.id
    WHERE ws.status = ?
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

  return LastWorkoutCompletedCardVm(
    workoutName: workoutName,
    nrOfExercises: nrOfExercises,
    workoutDuration: workoutDuration,
  );
}

final lastWorkoutCompletedProvider =
    AsyncNotifierProvider<
      LastWorkoutCompletedNotifier,
      LastWorkoutCompletedCardVm?
    >(LastWorkoutCompletedNotifier.new);

class LastWorkoutCompletedNotifier
    extends AsyncNotifier<LastWorkoutCompletedCardVm?> {
  @override
  FutureOr<LastWorkoutCompletedCardVm?> build() {
    ref.watch(currentSessionStatusProvider);
    return _loadLastWorkout();
  }
}
