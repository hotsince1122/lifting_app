import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/split_days.dart';

Future<List<SplitDay>> _loadSplitFromDb() async {
  final db = await AppDatabases.getDatabase();
  final data = await db.query('split_plan', orderBy: 'order_idx ASC');

  return data
      .map(
        (row) => SplitDay(
          name: row['name'] as String,
          orderIndex: row['order_idx'] as int,
          id: row['id'] as String,
          selectedPreset: row['is_selected_preset'] as String?,
        ),
      )
      .toList();
}

final splitPlanProvider =
    AsyncNotifierProvider<SplitPlanNotifier, List<SplitDay>>(
      SplitPlanNotifier.new,
    );

class SplitPlanNotifier extends AsyncNotifier<List<SplitDay>> {
  @override
  Future<List<SplitDay>> build() {
    return _loadSplitFromDb();
  }

  Future<void> changeSplit(List<SplitDay> newSplit) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete('split_plan');

      for (final splitDay in newSplit) {
        await txn.insert('split_plan', {
          'id': splitDay.id,
          'order_idx': splitDay.orderIndex,
          'name': splitDay.name,
          'is_selected_preset': splitDay.selectedPreset,
        });
      }
    });

    state = AsyncData(newSplit);
  }
}
