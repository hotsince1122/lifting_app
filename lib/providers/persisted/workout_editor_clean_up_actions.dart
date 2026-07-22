import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/data/queries/populate_workout_session_sets.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

final workoutEditorCleanUpActionsProvider =
    AsyncNotifierProvider<WorkoutEditorCleanUpActionsNotifier, void>(
      WorkoutEditorCleanUpActionsNotifier.new,
    );

class WorkoutEditorCleanUpActionsNotifier extends AsyncNotifier<void> {
  @override
  void build() {
    return;
  }

  Future<String?> _loadWorkoutSessionDayId(int workoutSessionId) async {
    final db = await AppDatabase.getDatabase();

    final data = await db.rawQuery(
      '''
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
      ''',
      [workoutSessionId],
    );

    if (data.isEmpty) return null;

    return data.first['day_id'] as String?;
  }

  Future<bool> checkIfAnySetEmpty(int workoutSessionId) async {
    final db = await AppDatabase.getDatabase();

    return db.transaction((txn) async {
      final data = await txn.rawQuery(
        '''
      SELECT id
      FROM active_session_sets
      WHERE workout_session_id = ?
        AND (
          actual_weight IS NULL
          OR actual_repetitions IS NULL
        )
      LIMIT 1;
      ''',
        [workoutSessionId],
      );

      return data.isNotEmpty;
    });
  }

  Future<bool> checkIfUserModifiedExercisesPlanned(int workoutSessionId) async {
    final dayId = await _loadWorkoutSessionDayId(workoutSessionId);
    if (dayId == null) return false;

    final db = await AppDatabase.getDatabase();

    final List<Exercise> exercisesPlanned = await loadPlannedExercises(
      db,
      workoutSessionId,
    );

    final List<String> exercisesExecutedIds = await loadExercisesExecutedIds(
      db,
      workoutSessionId,
    );

    if (exercisesPlanned.length != exercisesExecutedIds.length) return true;

    for (int i = 0; i < exercisesExecutedIds.length; i++) {
      if (exercisesExecutedIds[i] != exercisesPlanned[i].id) return true;
    }

    return false;
  }

  Future<void> saveEmptySetsWithHints(int workoutSessionId) async {
    final db = await AppDatabase.getDatabase();

    await db.transaction((txn) async {
      await txn.rawUpdate(
        '''
        UPDATE active_session_sets
        SET actual_weight = COALESCE(actual_weight, hint_weight),
            actual_repetitions = COALESCE(actual_repetitions, hint_repetitions),
            actual_notes = COALESCE(actual_notes, hint_notes)
        WHERE workout_session_id = ?
          AND (actual_weight IS NULL OR actual_repetitions IS NULL)
        ''',
        [workoutSessionId],
      );
    });
  }

  Future<void> updateCurrentPlan(int workoutSessionId) async {
    final db = await AppDatabase.getDatabase();

    final List<String> exercisesExecutedIdsInOrder =
        await loadExercisesExecutedIds(db, workoutSessionId);

    await db.transaction((txn) async {
      final data = await txn.rawQuery(
        '''
        SELECT day_id
        FROM workout_sessions
        WHERE id = ?
        ''',
        [workoutSessionId],
      );

      if (data.isEmpty) return;

      final dayId = data[0]['day_id'] as String?;
      if (dayId == null) return;

      await txn.rawDelete(
        '''
        DELETE FROM day_exercises
        WHERE day_id = ?
        ''',
        [dayId],
      );

      final batch = txn.batch();
      for (int i = 0; i < exercisesExecutedIdsInOrder.length; i++) {
        batch.insert('day_exercises', {
          'day_id': dayId,
          'exercise_id': exercisesExecutedIdsInOrder[i],
          'order_idx': i,
        });
      }
      await batch.commit(noResult: true);
    });
  }
}
