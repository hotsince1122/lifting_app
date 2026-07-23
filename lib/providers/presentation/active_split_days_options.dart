import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/models/view_model/workout_focus_view_data.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_days.dart';

final activeSplitDaysOptionsProvider =
    AsyncNotifierProvider<ActiveSplitDaysOptionsNotifier, List<WorkoutFocusViewData>>(
      ActiveSplitDaysOptionsNotifier.new,
    );

class ActiveSplitDaysOptionsNotifier
    extends AsyncNotifier<List<WorkoutFocusViewData>> {
  @override
  FutureOr<List<WorkoutFocusViewData>> build() async {
    final activeSplitDays = await ref.watch(activeSplitDaysProvider.future);

    final db = await AppDatabase.getDatabase();

    final workouts = <WorkoutFocusViewData>[];

    await db.transaction((txn) async {
      for (final splitDay in activeSplitDays) {
        var data = await txn.rawQuery(
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

        var muscleGroup = data.first['muscleGroups'] as String?;
        if (muscleGroup != null && !muscleGroup.contains(' ')) {
          muscleGroup += ' focused';
        }

        data = await txn.rawQuery(
          '''
          SELECT COUNT(*) as nrOfExercises
          FROM day_exercises
          WHERE day_id = ?
          ''',
          [splitDay.id],
        );

        final nrOfExercises = data.isEmpty
            ? 0
            : data.first['nrOfExercises'] as int;

        workouts.add(
          WorkoutFocusViewData(
            workoutName: splitDay.name,
            muscleGroups: muscleGroup ?? 'no muscle groups',
            nrOfExercises: nrOfExercises,
            dayId: splitDay.id,
          ),
        );
      }
    });

    return workouts;
  }
}
