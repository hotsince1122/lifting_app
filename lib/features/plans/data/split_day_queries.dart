import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/build_placeholder_for_sqlite.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';

Future<List<String>> loadActiveSplitDaysIds() async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery('''
    SELECT sd.id AS id
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_active = 1
    ORDER BY sd.order_idx
    ''');

  return data.map((row) => row['id'] as String).toList();
}

Future<String> loadSplitDayName(String dayId) async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
      SELECT name
      FROM split_days
      WHERE id = ?
      ''',
    [dayId],
  );

  if (data.isEmpty) {
    throw StateError('Split plan with id $dayId was not found.');
  }

  return data.first['name'] as String;
}

Future<SplitDay?> loadSplitDayById(String dayId) async {
  final db = await AppDatabase.getDatabase();
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
  return SplitDay(
    id: row['id'] as String,
    name: row['name'] as String,
    orderIndex: row['order_idx'] as int,
  );
}

Future<SplitDay> loadSplitDayByOrderIndex(
  List<String> splitDayIds,
  int orderIndex,
) async {
  final db = await AppDatabase.getDatabase();
  final placeholder = buildPlaceholder(splitDayIds.length);
  final data = await db.rawQuery(
    '''
      SELECT id, name, order_idx
      FROM split_days
      WHERE id IN ($placeholder)
        AND order_idx = ?
      ''',
    [...splitDayIds, orderIndex],
  );

  if (data.isEmpty) {
    throw StateError('Split day with order index $orderIndex was not found.');
  }

  final row = data.first;
  return SplitDay(
    id: row['id'] as String,
    name: row['name'] as String,
    orderIndex: row['order_idx'] as int,
  );
}

Future<List<SplitDay>> loadSplitDays(int splitId) async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
    SELECT name, order_idx AS orderIndex, id
    FROM split_days
    WHERE split_id = ?
    ORDER BY order_idx
    ''',
    [splitId],
  );

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
