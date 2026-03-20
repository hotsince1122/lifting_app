import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';
import 'package:lifting_tracker_app/models/entity/split_plan.dart';

Future<SplitPlan?> _loadSplitFromDb() async {
  final db = await AppDatabases.getDatabase();
  final data = await db.query(
    'split_plans',
    where: 'is_active = ?',
    whereArgs: [1],
    limit: 1,
  );

  if (data.isEmpty) {
    return null;
  }

  final row = data.first;

  return SplitPlan(
    id: row['id'] as int,
    name: row['name'] as String,
    isActive: row['is_active'] as int == 1,
    isPreset: row['is_preset'] as int == 1,
  );
}

final activeSplitPlanProvider =
    AsyncNotifierProvider<ActiveSplitPlanNotifier, SplitPlan?>(
      ActiveSplitPlanNotifier.new,
    );

class ActiveSplitPlanNotifier extends AsyncNotifier<SplitPlan?> {
  @override
  FutureOr<SplitPlan?> build() {
    return _loadSplitFromDb();
  }

  Future<void> addAndChangeToCustom(List<SplitDay> newSplit) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.update('split_plans', {'is_active': 0});

      final newSplitPlanId = await txn.insert('split_plans', {
        'name': 'Custom',
        'is_preset': 0,
        'is_active': 1,
      });

      for (final splitDay in newSplit) {
        await txn.insert('split_days', {
          'id': splitDay.id,
          'split_id': newSplitPlanId,
          'order_idx': splitDay.orderIndex,
          'name': splitDay.name,
        });
      }
    });

    state = AsyncData(await _loadSplitFromDb());
  }

  Future<void> changeToExisting(int splitId) async {
    final db = await AppDatabases.getDatabase();

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

    state = AsyncData(await _loadSplitFromDb());
  }
}