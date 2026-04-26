import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:sqflite/sqflite.dart';

String buildPlaceholder(int length) {
  return List<String>.generate(length, (_) => '?').join(', ');
}

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

Future<int> loadNextCycleIndex(
  Database db,
  List<String> activeSplitDaysIds,
) async {
  final placeholder = buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery('''
    SELECT cycle_index
    FROM workout_sessions
    WHERE day_id IN ($placeholder)
      AND status = ?
      AND finished_at IS NOT NULL
    ORDER BY finished_at DESC
    LIMIT 1
    ''', [...activeSplitDaysIds, WorkoutSessionStatuses.completedStatus]);

  if (data.isEmpty) return 0;

  return ((data.first['cycle_index'] as int) + 1) % activeSplitDaysIds.length;
}