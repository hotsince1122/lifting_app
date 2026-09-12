import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_sql_keys.dart';

Future<void> setAsCompleted() async {
  await _saveSetupCompletion(true);
}

Future<void> reset() async {
  await _saveSetupCompletion(false);
}

Future<void> _saveSetupCompletion(bool isCompleted) async {
  final db = await AppDatabase.getDatabase();
  final didUpdate = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET $setupStatusSqlKey = ?
    WHERE id = 1
    ''',
    [isCompleted ? 1 : 0],
  );

  if (didUpdate != 1) {
    throw StateError('Could not persist onboarding completion.');
  }
}
