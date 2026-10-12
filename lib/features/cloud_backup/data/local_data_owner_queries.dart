import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<String?> loadLocalDataOwnerUid() async {
  final db = await AppDatabase.getDatabase();

  final row = await db.rawQuery('''
    SELECT local_data_owner_uid
    FROM app_settings
    WHERE id = 1
    ''');

  if (row.isEmpty) {
    throw StateError('App settings singleton should have one row.');
  }

  return row.first['local_data_owner_uid'] as String?;
}

Future<bool> hasLocalWorkoutProgress() async {
  final db = await AppDatabase.getDatabase();

  final row = await db.rawQuery('''
    SELECT EXISTS(SELECT 1 FROM workout_sessions) AS has_progress
    ''');

  if (row.isEmpty) {
    throw StateError('The query should return 1 or 0');
  }

  final hasProgress = row.first['has_progress'] as int;

  return hasProgress == 1;
}
