import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/progress/data/progress_sql_keys.dart';

Future<int?> loadWeekStreak() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery('''
    SELECT $weekStreakSqlKey
    FROM app_settings
    WHERE id = 1
    ''');

  if (data.isEmpty) return null;

  return data.first[weekStreakSqlKey] as int?;
}
