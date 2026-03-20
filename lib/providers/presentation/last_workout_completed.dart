import 'dart:async';

import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/last_workout_completed_card_vm.dart';
import 'package:riverpod/riverpod.dart';

Future<LastWorkoutCompletedCardVm?> _loadLastWorkout() async {
  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery('''
    SELECT sd.name AS workoutName,
      cw.performed_exercises AS nrOfExercises,
      cw.duration_seconds AS workoutDuration
    FROM completed_workouts cw
    JOIN split_days sd ON cw.day_id = sd.id
    ORDER BY cw.performed_at DESC
    LIMIT 1
    ''');

  if (data.isEmpty) return null;

  return data
      .map(
        (row) => LastWorkoutCompletedCardVm(
          workoutName: row['workoutName'] as String,
          nrOfExercises: row['nrOfExercises'] as int,
          workoutDuration: row['workoutDuration'] as int,
        ),
      )
      .first;
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
    return _loadLastWorkout();
  }
}