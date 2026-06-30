import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/workout_focus_vm.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_days.dart';

final activeSplitDaysVmProvider =
    AsyncNotifierProvider<ActiveSplitDaysVmNotifier, List<WorkoutFocusVm>>(
      ActiveSplitDaysVmNotifier.new,
    );

class ActiveSplitDaysVmNotifier extends AsyncNotifier<List<WorkoutFocusVm>> {
  @override
  FutureOr<List<WorkoutFocusVm>> build() async {
    final activeSplitDays = await ref.watch(activeSplitDaysProvider.future);

    final db = await AppDatabases.getDatabase();

    final workouts = <WorkoutFocusVm>[];

    await db.transaction((txn) async {
      for (final splitDay in activeSplitDays) {
        final data = await txn.rawQuery(
          '''
          SELECT GROUP_CONCAT(muscle_group, ' / ') AS muscleGroups
          FROM ( 
            SELECT DISTINCT e.muscle_group
            FROM exercises e
            JOIN day_exercises de ON de.exercise_id = e.id
            WHERE de.day_id = ?
            ORDER BY e.muscle_group
          )
          ''',
          [splitDay.id],
        );

        if (data.isEmpty) {
          workouts.add(
            WorkoutFocusVm(
              workoutName: splitDay.name,
              muscleGroups: null,
              nrOfExercises: null,
              dayId: splitDay.id,
            ),
          );
        }

        workouts.add(
          WorkoutFocusVm(
            workoutName: splitDay.name,
            muscleGroups: data.first['muscleGroups'] as String,
            nrOfExercises: null,
            dayId: splitDay.id,
          ),
        );
      }
    });

    return workouts;
  }
}
