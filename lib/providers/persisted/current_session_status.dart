import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:sqflite/sqflite.dart';

FutureOr<bool> _loadSessionStatus() async {
  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery(
    '''
    SELECT id
    FROM workout_sessions
    WHERE status = ?
    ''',
    [WorkoutSessionStatuses.activeStatus],
  );

  if (data.isEmpty) return false;

  return true;
}

FutureOr<String> _nextDayInCycleDayId(
  Database db,
  List<String> activeSplitDaysIds,
  int nextInCycleIndex,
) async {
  final String placeholder = buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery(
    '''
    SELECT id
    FROM split_days
    WHERE id IN ($placeholder)
      AND order_idx = ?
    ''',
    [...activeSplitDaysIds, nextInCycleIndex],
  );

  final row = data.first;

  return row['id'] as String;
}

final currentSessionStatusProvider =
    AsyncNotifierProvider<CurrentSessionStatusNotifier, bool>(
      CurrentSessionStatusNotifier.new,
    );

class CurrentSessionStatusNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return _loadSessionStatus();
  }

  Future<int> startSession() async {
    final db = await AppDatabases.getDatabase();

    final List<String> activeSplitDaysIds = await loadActiveSplitDaysIds(db);
    final int nextInCycleIndex = await loadNextCycleIndex(
      db,
      activeSplitDaysIds,
    );
    final String nextDayInCycleDayId = await _nextDayInCycleDayId(
      db,
      activeSplitDaysIds,
      nextInCycleIndex,
    );

    final sessionId = await db.transaction<int>(
      (txn) => txn.rawInsert(
        '''
        INSERT INTO workout_sessions (day_id, started_at, cycle_index, status)
        VALUES (?, ?, ?, ?)
        ''',
        [
          nextDayInCycleDayId,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          nextInCycleIndex,
          WorkoutSessionStatuses.activeStatus,
        ],
      ),
    );

    state = AsyncData(true);
    return sessionId;
  }

  Future<void> endSession(int activeSessionId) async {
    final db = await AppDatabases.getDatabase();
    final finishedWeekday = DateTime.now().weekday;

    final didEndSession = await db.transaction<bool>((txn) async {
      final data = await txn.rawQuery(
        '''
        SELECT started_at
        FROM workout_sessions
        WHERE id = ? AND status = ?
        ''',
        [activeSessionId, WorkoutSessionStatuses.activeStatus],
      );

      if (data.isEmpty) return false;

      final workoutStartedAt = data[0]['started_at'] as int;

      final setsData = await txn.rawQuery(
        '''
        SELECT exercise_id AS ex_id,
          workout_session_id AS session_id,
          actual_weight AS weight,
          actual_repetitions AS repetitions,
          actual_notes AS notes,
          set_index AS set_index,
          exercise_order_index AS order_index,
          exercise_occurrence_index AS exercise_occurrence_index
        FROM active_session_sets
        WHERE is_deleted = 0
          AND actual_weight IS NOT NULL
          AND actual_repetitions IS NOT NULL
          AND workout_session_id = ?
        ''',
        [activeSessionId],
      );

      final batch = txn.batch();
      for (final setData in setsData) {
        batch.insert('logged_sets', setData);
      }
      await batch.commit(noResult: true);

      final rowsUpdated = await txn.rawUpdate(
        '''
        UPDATE workout_sessions
        SET finished_at = ?,
            duration_seconds = ?,
            status = ?
        WHERE id = ? AND status = ?
        ''',
        [
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - workoutStartedAt,
          WorkoutSessionStatuses.completedStatus,
          activeSessionId,
          WorkoutSessionStatuses.activeStatus,
        ],
      );

      return rowsUpdated == 1;
    });

    if (!didEndSession) return;

    await ref
        .read(weeklyWorkoutProgressProvider.notifier)
        .updateProgress(finishedWeekday);
    state = AsyncData(false);
  }
}
