import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';

Future<int> renameDay(String newName, String dayId) async {
  final db = await AppDatabase.getDatabase();

  return await db.transaction((txn) async {
    await txn.rawUpdate(
      '''
        UPDATE split_days
        SET name = ?
        WHERE id =?
        ''',
      [newName, dayId],
    );

    final data = await txn.rawQuery(
      '''
        SELECT split_id
        FROM split_days
        WHERE id = ?
        ''',
      [dayId],
    );

    if (data.isEmpty) {
      throw StateError('Cannot find split id with day id $dayId.');
    }

    return data.first['split_id'] as int;
  });
}

Future<void> deleteSplitDay(int splitId, String splitDayId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction<void>((txn) async {
    final splitDays = await txn.rawQuery(
      '''
        SELECT *
        FROM split_days
        WHERE id = ? AND split_id = ?
        LIMIT 1
        ''',
      [splitDayId, splitId],
    );

    if (splitDays.isEmpty) return;

    await txn.rawDelete(
      '''
        DELETE FROM day_exercises
        WHERE day_id = ?
        ''',
      [splitDayId],
    );

    await txn.rawUpdate(
      '''
        UPDATE workout_sessions
        SET day_id = NULL
        WHERE day_id = ?
        ''',
      [splitDayId],
    );

    final deletedDays = await txn.rawDelete(
      '''
        DELETE FROM split_days
        WHERE id = ? AND split_id = ?
        ''',
      [splitDayId, splitId],
    );

    if (deletedDays != 1) {
      throw Exception('Expected to delete exactly one split day.');
    }

    final remainingDays = await txn.rawQuery(
      '''
        SELECT id, order_idx
        FROM split_days
        WHERE split_id = ?
        ORDER BY order_idx, id
        ''',
      [splitId],
    );

    for (int i = 0; i < remainingDays.length; i++) {
      final currentOrderIndex = remainingDays[i]['order_idx'] as int;

      if (currentOrderIndex == i) continue;

      final updatedDays = await txn.rawUpdate(
        '''
          UPDATE split_days
          SET order_idx = ?
          WHERE id = ? AND split_id = ?
          ''',
        [i, remainingDays[i]['id'] as String, splitId],
      );

      if (updatedDays != 1) {
        throw Exception('Could not compact split day indexes.');
      }
    }
  });
}

Future<void> reorderSplitDays(
  List<SplitDay> normalizedDays,
  int splitId,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    for (int i = 0; i < normalizedDays.length; i++) {
      final updatedRows = await txn.rawUpdate(
        '''
              UPDATE split_days
              SET order_idx = ?
              WHERE id = ? AND split_id = ?
              ''',
        [i, normalizedDays[i].id, splitId],
      );

      if (updatedRows != 1) {
        throw StateError('Could not reorder split day ${normalizedDays[i].id}');
      }
    }
  });
}

Future<void> createNewDay(SplitDay newDay, int splitId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawInsert(
      '''
            INSERT INTO split_days(id, split_id, name, order_idx)
            VALUES (?, ?, ?, ?)
            ''',
      [newDay.id, splitId, newDay.name, newDay.orderIndex],
    );
  });
}
