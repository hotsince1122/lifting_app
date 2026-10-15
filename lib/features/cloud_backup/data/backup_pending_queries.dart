import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<bool> loadBackupPending() async {
  final db = await AppDatabase.getDatabase();

  final rows = await db.rawQuery('''
    SELECT backup_pending
    FROM app_settings
    WHERE id = 1
    ''');

  if (rows.isEmpty) {
    throw StateError('The app settings row was not found.');
  }

  final pending = rows.single['backup_pending'] as int;
  return pending == 1;
}
