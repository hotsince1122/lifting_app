import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/progress/data/progress_sql_keys.dart';

Future<void> saveWeekStreak(int streak) async {
  final db = await AppDatabase.getDatabase();
  final didUpdate = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET $weekStreakSqlKey = ?
    WHERE id = 1
    ''',
    [streak],
  );

  if (didUpdate != 1) {
    throw StateError('Could not save the week streak.');
  }
}
