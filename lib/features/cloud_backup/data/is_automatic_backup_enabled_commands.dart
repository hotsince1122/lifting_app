import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<void> setNewValueForAutomaticBackup(bool newValue) async {
  final db = await AppDatabase.getDatabase();

  final int newValueSql = newValue == true ? 1 : 0;

  await db.rawUpdate(
    '''
    UPDATE app_settings
    SET automatic_backup_enabled = ?
    WHERE id = 1
    ''',
    [newValueSql],
  );
}
