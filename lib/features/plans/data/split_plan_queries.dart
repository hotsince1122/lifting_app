import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/domain/active_workout_session_status_key.dart';

Future<int?> loadActiveSplitId() async {
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

Future<String> loadSplitName(int splitId) async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
      SELECT name
      FROM split_plans
      WHERE id = ?
      ''',
    [splitId],
  );

  if (data.isEmpty) {
    throw StateError('Split plan with id $splitId was not found.');
  }

  return data.first['name'] as String;
}

Future<List<int>> loadSplitPlanIds() async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery('''
    SELECT id
    FROM split_plans
    ''');

  return data.map((row) => row['id'] as int).toList();
}

Future<Map<String, Object?>?> loadSplitPlanProviderData(int splitId) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.query(
    'split_plans',
    where: 'id = ?',
    whereArgs: [splitId],
    limit: 1,
  );

  if (data.isEmpty) return null;

  return data.first;
}

Future<bool> hasActiveSessionInSplit(int splitId) async {
  final db = await AppDatabase.getDatabase();

  final activeSessions = await db.rawQuery(
    '''
    SELECT 1
    FROM workout_sessions ws
    JOIN split_days sd ON sd.id = ws.day_id
    WHERE sd.split_id = ?
      AND ws.status = ?
    LIMIT 1
    ''',
    [splitId, activeWorkoutSessionStatus],
  );

  return activeSessions.isNotEmpty;
}
