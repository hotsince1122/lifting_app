import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/build_placeholder_for_sqlite.dart';
import 'package:lifting_tracker_app/models/entity/split_plan.dart';

Future<SplitPlan?> _loadSplitPlan(int splitId) async {
  final db = await AppDatabase.getDatabase();
  var data = await db.query(
    'split_plans',
    where: 'id = ?',
    whereArgs: [splitId],
    limit: 1,
  );

  if (data.isEmpty) return null;

  final row = data.first;
  final splitName = row['name'] as String;
  final isActive = row['is_active'] as int == 1;
  final isPreset = row['is_preset'] as int == 1;

  data = await db.rawQuery(
    '''
    SELECT id
    FROM split_days
    WHERE split_id = ?
    ORDER BY order_idx
    ''',
    [splitId],
  );

  final splitDayIds = data.map((row) => row['id'] as String).toList();
  final splitCycleLengthInDays = splitDayIds.length;

  var nrOfExercises = 0;

  if (splitDayIds.isNotEmpty) {
    final placeholder = buildPlaceholder(splitDayIds.length);

    data = await db.rawQuery('''
      SELECT COUNT(*) AS nrOfExercises
      FROM day_exercises
      WHERE day_id IN ($placeholder)
      ''', splitDayIds);

    nrOfExercises = data.first['nrOfExercises'] as int;
  }

  return SplitPlan(
    id: splitId,
    name: splitName,
    isActive: isActive,
    isPreset: isPreset,
    cycleLengthInDays: splitCycleLengthInDays,
    nrOfExercises: nrOfExercises,
  );
}

final splitPlanProvider = FutureProvider.autoDispose.family<SplitPlan?, int>(
  (ref, splitId) => _loadSplitPlan(splitId),
);
