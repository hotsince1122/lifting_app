import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/preset_split_plans_card_vm.dart';

Future<List<PresetSplitPlanCardVm>> _loadPresetsFromDb() async {
  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery('''
  SELECT
   ordered.splitId,
   ordered.splitPlanName,
   GROUP_CONCAT(ordered.dayName, ' / ') AS splitDaysNames,
   COUNT(*) AS nrOfDays
  FROM (
    SELECT
      sp.id AS splitId,
      sp.name AS splitPlanName,
      sd.name AS dayName
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_preset = 1
    ORDER BY sp.id, sd.order_idx
  ) ordered
  GROUP BY
    ordered.splitId,
    ordered.splitPlanName
  ORDER BY ordered.splitId;
  ''');

  return data
      .map(
        (row) => PresetSplitPlanCardVm(
          splitId: row['splitId'] as int,
          splitPlanName: row['splitPlanName'] as String,
          splitDaysNames: row['splitDaysNames'] as String,
          nrOfDays: row['nrOfDays'] as int,
        ),
      )
      .toList();
}

final presetSplitVmProvider =
    AsyncNotifierProvider<PresetSplitVmNotifier, List<PresetSplitPlanCardVm>>(
      PresetSplitVmNotifier.new,
    );

class PresetSplitVmNotifier extends AsyncNotifier<List<PresetSplitPlanCardVm>> {
  @override
  FutureOr<List<PresetSplitPlanCardVm>> build() {
    return _loadPresetsFromDb();
  }

  FutureOr<void> refresh() async {
    state = AsyncData(await _loadPresetsFromDb());
  }
}
