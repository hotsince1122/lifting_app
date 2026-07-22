import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/providers/persisted/exercises_in_a_day.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';
import 'package:lifting_tracker_app/providers/persisted/split_name.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/preset_split_vm.dart';
import 'package:lifting_tracker_app/providers/presentation/split_day_summary_tile.dart';

Future<List<int>> _loadSplitPlanIds() async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery('''
    SELECT id
    FROM split_plans
    ''');

  return data.map((row) => row['id'] as int).toList();
}

enum DeleteSplitPlanResult { success, sessionInSplitActive }

Future<DeleteSplitPlanResult> _deleteSplitPlanFromDb(int splitId) async {
  final db = await AppDatabase.getDatabase();

  return db.transaction<DeleteSplitPlanResult>((txn) async {
    final activeSessions = await txn.rawQuery(
      '''
      SELECT 1
      FROM workout_sessions ws
      JOIN split_days sd ON sd.id = ws.day_id
      WHERE sd.split_id = ?
        AND ws.status = ?
      LIMIT 1
      ''',
      [splitId, WorkoutSessionStatuses.activeStatus],
    );

    if (activeSessions.isNotEmpty) {
      return DeleteSplitPlanResult.sessionInSplitActive;
    }

    await txn.rawUpdate(
      '''
      UPDATE workout_sessions
      SET day_id = NULL
      WHERE day_id IN (
        SELECT id
        FROM split_days
        WHERE split_id = ?
      )
      ''',
      [splitId],
    );

    await txn.rawDelete(
      '''
      DELETE FROM day_exercises
      WHERE day_id IN (
        SELECT id
        FROM split_days
        WHERE split_id = ?
      )
      ''',
      [splitId],
    );

    await txn.rawDelete(
      '''
      DELETE FROM split_days
      WHERE split_id = ?
      ''',
      [splitId],
    );

    final deletedPlans = await txn.rawDelete(
      '''
      DELETE FROM split_plans
      WHERE id = ?
      ''',
      [splitId],
    );

    if (deletedPlans != 1) {
      throw Exception('Could not delete split plan $splitId.');
    }

    return DeleteSplitPlanResult.success;
  });
}

final splitPlansIdsProvider =
    AsyncNotifierProvider<SplitPlansIdsNotifier, List<int>>(
      SplitPlansIdsNotifier.new,
    );

class SplitPlansIdsNotifier extends AsyncNotifier<List<int>> {
  @override
  FutureOr<List<int>> build() {
    return _loadSplitPlanIds();
  }

  Future<DeleteSplitPlanResult> deletePlan(int splitId) async {
    final result = await _deleteSplitPlanFromDb(splitId);

    if (result == DeleteSplitPlanResult.sessionInSplitActive) {
      return DeleteSplitPlanResult.sessionInSplitActive;
    }

    final currentIds = state.value;
    state = AsyncData(
      currentIds == null
          ? await _loadSplitPlanIds()
          : currentIds.where((id) => id != splitId).toList(),
    );

    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(splitNameProvider(splitId));
    ref.invalidate(splitDaysProvider(splitId));
    ref.invalidate(exercisesInADayProvider);
    ref.invalidate(splitDaySummaryProvider);
    ref.invalidate(presetSplitVmProvider);

    return DeleteSplitPlanResult.success;
  }

  Future<bool> hasActiveSessionInSplit(int splitId) async {
    final db = await AppDatabase.getDatabase();

    final activeSessions = await db.rawQuery(
      '''
    SELECT 1
    FROM workout_sessions ws
    JOIN split_days sd ON sd.id = ws.day_id
    WHERE sd.split_id = ?
      AND ws.status = ?
    LIMIT 1
    ''',
      [splitId, WorkoutSessionStatuses.activeStatus],
    );

    return activeSessions.isNotEmpty;
  }
}
