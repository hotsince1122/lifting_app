import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';

Future<List<SplitDay>> _loadDaysFromActiveSplit() async {
  final db = await AppDatabases.getDatabase();

  final data = await db.rawQuery('''
    SELECT sd.name AS name, sd.order_idx AS orderIndex, sd.id AS id
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_active = 1
    ORDER BY sd.order_idx
    ''');

  return data
      .map(
        (row) => SplitDay(
          name: row['name'] as String,
          orderIndex: row['orderIndex'] as int,
          id: row['id'] as String,
        ),
      )
      .toList();
}

final activeSplitDaysProvider =
    AsyncNotifierProvider<ActiveSplitDaysProvider, List<SplitDay>>(
      ActiveSplitDaysProvider.new,
    );

class ActiveSplitDaysProvider extends AsyncNotifier<List<SplitDay>> {
  @override
  FutureOr<List<SplitDay>> build() {
    return _loadDaysFromActiveSplit();
  }
}
