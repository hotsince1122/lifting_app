import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_sql_keys.dart';

Future<bool> loadSetupCompletion() async {
  final db = await AppDatabase.getDatabase();
  final data = await db.rawQuery('''
    SELECT $setupStatusSqlKey
    FROM app_settings
    WHERE id = 1
    ''');

  if (data.isEmpty) return false;

  return data.first[setupStatusSqlKey] == 1;
}
