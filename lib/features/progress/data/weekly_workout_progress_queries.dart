import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/progress/data/progress_sql_keys.dart';

Future<int?> loadWeeklyWorkoutTarget() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery('''
    SELECT $weeklyWorkoutTargetSqlKey
    FROM app_settings
    WHERE id = 1
    ''');

  if (data.isEmpty) return null;

  return data.first[weeklyWorkoutTargetSqlKey] as int?;
}

Future<List<bool>?> loadWeeklyGymAttendance() async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery('''
    SELECT $weeklyGymAttendanceSqlKey
    FROM app_settings
    WHERE id = 1
    ''');

  if (data.isEmpty) return null;

  final encodedAttendance = data.first[weeklyGymAttendanceSqlKey] as String?;

  if (encodedAttendance == null) return null;

  return encodedAttendance.split('').map((value) => value == '1').toList();
}

Future<String?> loadWeeklyGymAttendanceWeekStart() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery('''
    SELECT $weeklyGymAttendanceWeekStartSqlKey
    FROM app_settings
    WHERE id = 1
    ''');

  if (data.isEmpty) return null;

  return data.first[weeklyGymAttendanceWeekStartSqlKey] as String?;
}
