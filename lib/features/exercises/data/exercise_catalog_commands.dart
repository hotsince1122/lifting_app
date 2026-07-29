import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';

Future<void> insertExercise(CatalogExercise exercise) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.insert('exercises', {
      'id': exercise.id,
      'name': exercise.name,
      'muscle_group': exercise.muscleGroup,
    });
  });
}

Future<void> updateExercise(CatalogExercise exercise) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.update(
      'exercises',
      {'name': exercise.name, 'muscle_group': exercise.muscleGroup},
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  });
}

Future<void> deleteExercise(String exerciseId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
  });
}
