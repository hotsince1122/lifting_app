import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/domain/custom_split.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plans_ids_controller.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/application/workout_focus_provider.dart';

Future<int?> _loadActiveSplitId() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.query(
    'split_plans',
    where: 'is_active = ?',
    whereArgs: [1],
    columns: ['id'],
    limit: 1,
  );

  return data.isEmpty ? null : data.first['id'] as int;
}

final activeSplitIdProvider =
    AsyncNotifierProvider<ActiveSplitIdController, int?>(
      ActiveSplitIdController.new,
    );

class ActiveSplitIdController extends AsyncNotifier<int?> {
  @override
  FutureOr<int?> build() {
    return _loadActiveSplitId();
  }

  Future<void> addAndChangeToCustom(CustomSplit newSplit) async {
    final db = await AppDatabase.getDatabase();
    final previousSplitId = state.value;

    final newSplitPlanId = await db.transaction((txn) async {
      await txn.update('split_plans', {'is_active': 0});

      final newSplitPlanId = await txn.insert('split_plans', {
        'name': newSplit.splitName,
        'is_preset': 0,
        'is_active': 1,
      });

      for (final splitDay in newSplit.splitDays) {
        await txn.insert('split_days', {
          'id': splitDay.id,
          'split_id': newSplitPlanId,
          'order_idx': splitDay.orderIndex,
          'name': splitDay.name,
        });
      }

      return newSplitPlanId;
    });

    if (previousSplitId != null) {
      ref.invalidate(splitPlanProvider(previousSplitId));
    }
    ref.invalidate(splitPlanProvider(newSplitPlanId));
    ref.invalidate(workoutFocusProvider);
    ref.invalidate(splitPlansIdsProvider);

    await ref.read(pickedNextSessionProvider.notifier).consumeId();

    state = AsyncData(newSplitPlanId);
  }

  Future<void> changeToExisting(int splitId) async {
    final db = await AppDatabase.getDatabase();
    final previousSplitId = state.value;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        '''
        UPDATE split_plans
        SET is_active = CASE
          WHEN id = ? THEN 1
          ELSE 0
        END;
        ''',
        [splitId],
      );
    });

    if (previousSplitId != null) {
      ref.invalidate(splitPlanProvider(previousSplitId));
    }
    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(workoutFocusProvider);
    ref.invalidate(splitPlansIdsProvider);

    await ref.read(pickedNextSessionProvider.notifier).consumeId();

    state = AsyncData(splitId);
  }
}
