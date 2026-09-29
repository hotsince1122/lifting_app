import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<bool> isAutomaticBackupEnabled() async {
  final db = await AppDatabase.getDatabase();

  final boolData = await db.rawQuery('''
    SELECT automatic_backup_enabled
    FROM app_settings
    WHERE id = 1
    ''');

  if (boolData.isEmpty) {
    throw StateError('Field cannot be null');
  }

  final isEnabled = boolData.first['automatic_backup_enabled'] as int;

  return isEnabled == 1 ? true : false;
}
