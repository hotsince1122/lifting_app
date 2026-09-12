import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/progress/data/progress_sql_keys.dart';

Future<void> saveWeeklyWorkoutTarget(int target) async {
  final db = await AppDatabase.getDatabase();

  final didUpdate = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET $weeklyWorkoutTargetSqlKey = ?
    WHERE id = 1
    ''',
    [target],
  );

  if (didUpdate != 1) {
    throw StateError('Could not save the weekly workout target.');
  }
}

Future<void> saveWeeklyGymAttendance(List<bool> attendance) async {
  final db = await AppDatabase.getDatabase();
  final encodedAttendance = attendance
      .map((didAttend) => didAttend ? '1' : '0')
      .join();

  final didUpdate = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET $weeklyGymAttendanceSqlKey = ?
    WHERE id = 1
    ''',
    [encodedAttendance],
  );

  if (didUpdate != 1) {
    throw StateError('Could not save the weekly gym attendance.');
  }
}

Future<void> saveWeeklyGymAttendanceWeekStart(String weekStart) async {
  final db = await AppDatabase.getDatabase();
  final didUpdate = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET $weeklyGymAttendanceWeekStartSqlKey = ?
    WHERE id = 1
    ''',
    [weekStart],
  );

  if (didUpdate != 1) {
    throw StateError('Could not save the weekly attendance week start.');
  }
}
