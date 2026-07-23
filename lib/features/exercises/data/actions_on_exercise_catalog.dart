import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/exercises/domain/exercise.dart';

Future<List<Exercise>> loadExercisesByMuscleGroup(
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
        (row) => Exercise(
          name: row['name'] as String,
          muscleGroup: row['muscle_group'] as String,
          id: row['id'] as String,
        ),
      )
      .toList();
}

Future<void> insertExercise(Exercise exercise) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
      await txn.insert('exercises', {
        'id': exercise.id,
        'name': exercise.name,
        'muscle_group': exercise.muscleGroup,
      });
    });
}

Future<void> updateExercise(Exercise exercise) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.update(
      'exercises',
      {
        'name': exercise.name,
        'muscle_group': exercise.muscleGroup,
      },
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
