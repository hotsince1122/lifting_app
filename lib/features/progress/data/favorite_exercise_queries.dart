import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<Set<String>> loadFavoriteExerciseIds() async {
  final db = await AppDatabase.getDatabase();
  final rows = await db.query(
    'favorite_exercises',
    columns: ['exercise_id'],
    orderBy: 'exercise_id',
  );

  return Set<String>.unmodifiable(
    rows.map((row) => row['exercise_id'] as String),
  );
}
