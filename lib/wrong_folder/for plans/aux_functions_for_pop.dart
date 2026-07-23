import 'package:sqflite/sqflite.dart';

Future<List<String>> loadActiveSplitDaysIds(Database db) async {
  final data = await db.rawQuery('''
    SELECT sd.id AS id
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_active = 1
    ORDER BY sd.order_idx
    ''');

  return data.map((row) => row['id'] as String).toList();
}