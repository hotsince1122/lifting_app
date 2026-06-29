import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/providers/persisted/workout_name.dart';
import 'package:lifting_tracker_app/providers/presentation/history_months.dart';
import 'package:lifting_tracker_app/providers/presentation/last_workout_completed.dart';
import 'package:lifting_tracker_app/providers/presentation/next_in_cycle.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_header_summary_card.dart';

final historyWorkoutActionsProvider =
    AsyncNotifierProvider<HistoryWorkoutActionsNotifier, void>(
      HistoryWorkoutActionsNotifier.new,
    );

class HistoryWorkoutActionsNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<bool> clearActiveSessionSets(int workoutSessionId) async {
    final db = await AppDatabases.getDatabase();

    try {
      await db.transaction((txn) async {
        await txn.rawDelete(
          '''
          DELETE FROM active_session_sets
          WHERE workout_session_id = ?
          ''',
          [workoutSessionId],
        );
      });
    } catch (_) {
      return false;
    }

    ref.invalidate(exercisesAndSetsProvider(workoutSessionId));
    return true;
  }

  Future<bool> saveEditedWorkout(
    int workoutSessionId, {
    required String workoutName,
  }) async {
    final db = await AppDatabases.getDatabase();
    final normalizedWorkoutName = normalizeWorkoutName(workoutName);

    try {
      await db.transaction((txn) async {
        await txn.rawUpdate(
          '''
          UPDATE workout_sessions
          SET workout_name = ?
          WHERE id = ?
          ''',
          [normalizedWorkoutName, workoutSessionId],
        );

        await txn.rawDelete(
          '''
          DELETE FROM logged_sets
          WHERE session_id = ?
          ''',
          [workoutSessionId],
        );

        final setsData = await txn.rawQuery(
          '''
          SELECT exercise_id AS ex_id,
            workout_session_id AS session_id,
            actual_weight AS weight,
            actual_repetitions AS repetitions,
            actual_notes AS notes,
            set_index,
            exercise_order_index AS order_index,
            exercise_occurrence_index,
            is_warmup
          FROM active_session_sets
          WHERE workout_session_id = ?
            AND actual_weight IS NOT NULL
            AND actual_repetitions IS NOT NULL
          ORDER BY exercise_order_index, set_index
          ''',
          [workoutSessionId],
        );

        final batch = txn.batch();
        for (final setData in setsData) {
          batch.insert('logged_sets', setData);
        }
        await batch.commit(noResult: true);

        await txn.rawDelete(
          '''
          DELETE FROM active_session_sets
          WHERE workout_session_id = ?
          ''',
          [workoutSessionId],
        );
      });
    } catch (_) {
      return false;
    }

    ref.invalidate(historyMonthsProvider);
    ref.invalidate(lastWorkoutCompletedProvider);
    ref.invalidate(workoutHeaderSummaryCardProvider);
    ref.invalidate(workoutNameProvider(workoutSessionId));
    ref.invalidate(exercisesAndSetsProvider(workoutSessionId));
    return true;
  }

  Future<bool> deleteWorkout(int workoutId) async {
    final db = await AppDatabases.getDatabase();

    try {
      final didSucceed = await db.transaction((txn) async {
        final finishedMilisecondsSinceEpoch = await txn.rawQuery(
          '''
          SELECT finished_at
          FROM workout_sessions
          WHERE id = ?
          ''',
          [workoutId],
        );

        if (finishedMilisecondsSinceEpoch.isEmpty) {
          return false;
        }
        if (finishedMilisecondsSinceEpoch.first['finished_at'] == null) {
          return false;
        }

        await txn.rawDelete(
          '''
          DELETE FROM workout_sessions
          WHERE id = ?
          ''',
          [workoutId],
        );

        final finishedDateTime = DateTime.fromMillisecondsSinceEpoch(
          (finishedMilisecondsSinceEpoch.first['finished_at'] as int) * 1000,
        );

        final didSucceed = await ref
            .read(weeklyWorkoutProgressProvider.notifier)
            .rollbackProgressIfRequired(finishedDateTime, txn);

        if (!didSucceed) throw 'rollback transaction';

        return true;
      });
      if (!didSucceed) return false;
    } catch (error) {
      return false;
    }

    ref.invalidate(lastWorkoutCompletedProvider);
    ref.invalidate(nextInCycleProvider);

    ref.invalidate(historyMonthsProvider);
    ref.invalidate(workoutHeaderSummaryCardProvider);

    return true;
  }
}
