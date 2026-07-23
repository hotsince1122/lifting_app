import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';

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
    final db = await AppDatabase.getDatabase();

    final data = await db.rawQuery(
      '''
      SELECT workout_name
      FROM workout_sessions
      WHERE id = ?
      ''',
      [workoutId],
    );

    if (data.isEmpty) return '';

    final row = data.first;

    return row['workout_name'] as String;
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

    try {
      final db = await AppDatabase.getDatabase();

      await db.rawUpdate(
        '''
        UPDATE workout_sessions
        SET workout_name = ?
        WHERE id = ?
        ''',
        [normalizedName, workoutId],
      );
    } catch (_) {
      return;
    }
  }
}
