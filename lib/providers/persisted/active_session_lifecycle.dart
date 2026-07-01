import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_funcs.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/data/queries/repeat_workout.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/providers/persisted/picked_next_session_provider.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_header_summary_card.dart';
import 'package:sqflite/sqflite.dart';

FutureOr<bool> _hasActiveSession() async {
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

class _NextCycleDay {
  const _NextCycleDay({
    required this.id,
    required this.name,
    required this.workoutIndex,
  });

  final String id;
  final String name;
  final int workoutIndex;
}

FutureOr<_NextCycleDay> _nextDayInCycleDay(
  Database db,
  List<String> activeSplitDaysIds,
  int nextInCycleIndex,
) async {
  final String placeholder = buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery(
    '''
    SELECT id, name
    FROM split_days
    WHERE id IN ($placeholder)
      AND order_idx = ?
    ''',
    [...activeSplitDaysIds, nextInCycleIndex],
  );

  final row = data.first;

  return _NextCycleDay(
    id: row['id'] as String,
    name: row['name'] as String,
    workoutIndex: nextInCycleIndex,
  );
}

FutureOr<_NextCycleDay?> _splitDayById(Database db, String dayId) async {
  final data = await db.rawQuery(
    '''
    SELECT id, name, order_idx
    FROM split_days
    WHERE id = ?
    ''',
    [dayId],
  );

  if (data.isEmpty) return null;

  final row = data.first;

  return _NextCycleDay(
    id: row['id'] as String,
    name: row['name'] as String,
    workoutIndex: row['order_idx'] as int,
  );
}

FutureOr<_NextCycleDay> _nextScheduledCycleDay(
  Database db,
  List<String> activeSplitDaysIds,
) async {
  final int nextInCycleIndex = await loadNextCycleIndex(db, activeSplitDaysIds);

  return _nextDayInCycleDay(db, activeSplitDaysIds, nextInCycleIndex);
}

const _quickWorkoutName = 'Quick Workout';

Future<int> _insertQuickWorkout(
  DatabaseExecutor db, {
  required String workoutName,
}) {
  final trimmedWorkoutName = workoutName.trim();

  return db.rawInsert(
    '''
    INSERT INTO workout_sessions (
      workout_name,
      started_at,
      status
    )
    VALUES (?, ?, ?)
    ''',
    [
      trimmedWorkoutName.isEmpty ? _quickWorkoutName : trimmedWorkoutName,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      WorkoutSessionStatuses.activeStatus,
    ],
  );
}

final activeSessionLifecycleProvider =
    AsyncNotifierProvider<ActiveSessionLifecycleNotifier, bool>(
      ActiveSessionLifecycleNotifier.new,
    );

class ActiveSessionLifecycleNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return _hasActiveSession();
  }

  Future<int> startSession() async {
    final db = await AppDatabases.getDatabase();

    final activeSplitDaysIds = await loadActiveSplitDaysIds(db);
    final pickedWorkoutDayId = await ref.read(pickedNextSessionProvider.future);

    final isPickedDayInActiveSplit =
        pickedWorkoutDayId != null &&
        activeSplitDaysIds.contains(pickedWorkoutDayId);

    final pickedDay = isPickedDayInActiveSplit
        ? await _splitDayById(db, pickedWorkoutDayId)
        : null;

    if (pickedWorkoutDayId != null && pickedDay == null) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }

    final nextDayInCycleDay =
        pickedDay ?? await _nextScheduledCycleDay(db, activeSplitDaysIds);

    final sessionId = await db.transaction<int>(
      (txn) => txn.rawInsert(
        '''
        INSERT INTO workout_sessions (
          workout_name,
          day_id,
          started_at,
          cycle_index,
          status
        )
        VALUES (?, ?, ?, ?, ?)
        ''',
        [
          nextDayInCycleDay.name,
          nextDayInCycleDay.id,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          nextDayInCycleDay.workoutIndex,
          WorkoutSessionStatuses.activeStatus,
        ],
      ),
    );

    if (pickedDay != null) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }

    state = AsyncData(true);
    return sessionId;
  }

  Future<int> startQuickWorkout({
    String workoutName = _quickWorkoutName,
  }) async {
    final db = await AppDatabases.getDatabase();

    final sessionId = await db.transaction<int>(
      (txn) => _insertQuickWorkout(txn, workoutName: workoutName),
    );

    state = AsyncData(true);
    return sessionId;
  }

  Future<int?> startRepeatedWorkout(int sourceWorkoutId) async {
    final db = await AppDatabases.getDatabase();

    final newWorkoutId = await db.transaction<int?>((txn) async {
      final workoutName = await getWorkoutNameFromWorkoutID(
        txn,
        sourceWorkoutId,
      );

      if (workoutName == null) return null;

      final newWorkoutId = await _insertQuickWorkout(
        txn,
        workoutName: workoutName,
      );

      await loadExercisesFromSourceWorkoutInDb(
        txn,
        sourceWorkoutId,
        newWorkoutId,
      );

      return newWorkoutId;
    });

    if (newWorkoutId == null) return null;

    state = AsyncData(true);
    return newWorkoutId;
  }

  Future<void> endSession(int workoutSessionId) async {
    final db = await AppDatabases.getDatabase();
    final finishedWeekday = DateTime.now().weekday;

    final didEndSession = await db.transaction<bool>((txn) async {
      final data = await txn.rawQuery(
        '''
        SELECT started_at
        FROM workout_sessions
        WHERE id = ? AND status = ?
        ''',
        [workoutSessionId, WorkoutSessionStatuses.activeStatus],
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
          exercise_occurrence_index AS exercise_occurrence_index,
          is_warmup AS is_warmup
        FROM active_session_sets
        WHERE actual_weight IS NOT NULL
          AND actual_repetitions IS NOT NULL
          AND workout_session_id = ?
        ''',
        [workoutSessionId],
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
          workoutSessionId,
          WorkoutSessionStatuses.activeStatus,
        ],
      );

      return rowsUpdated == 1;
    });

    if (!didEndSession) return;

    await ref
        .read(weeklyWorkoutProgressProvider.notifier)
        .updateProgress(finishedWeekday);

    //so the summary card updates for the particular workout id
    ref.invalidate(workoutHeaderSummaryCardProvider);
    state = AsyncData(false);
  }
}
