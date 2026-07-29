import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';

Future<List<CatalogExercise>> loadExercisesByMuscleGroup(
  String muscleGroup,
) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.query(
    'exercises',
    where: 'muscle_group = ?',
    whereArgs: [muscleGroup],
  );

  return data
      .map(
        (row) => CatalogExercise(
          name: row['name'] as String,
          muscleGroup: row['muscle_group'] as String,
          id: row['id'] as String,
        ),
      )
      .toList();
}