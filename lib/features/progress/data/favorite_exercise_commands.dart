import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

Future<void> addFavoriteExercise(String exerciseId) async {
  final db = await AppDatabase.getDatabase();
  await db.insert('favorite_exercises', {
    'exercise_id': exerciseId,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}

Future<void> removeFavoriteExercise(String exerciseId) async {
  final db = await AppDatabase.getDatabase();
  await db.delete(
    'favorite_exercises',
    where: 'exercise_id = ?',
    whereArgs: [exerciseId],
  );
}
