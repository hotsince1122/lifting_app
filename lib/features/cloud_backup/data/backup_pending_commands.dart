import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<void> setBackupPending(bool pending) async {
  final db = await AppDatabase.getDatabase();

  final rowsUpdated = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET backup_pending = ?
    WHERE id = 1
    ''',
    [pending ? 1 : 0],
  );

  if (rowsUpdated != 1) {
    throw StateError('The backup pending flag could not be updated.');
  }
}
