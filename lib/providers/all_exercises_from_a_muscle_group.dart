import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/exercise.dart';

Future<List<Exercise>> _loadAllExercisesInAMuscleGroupFromDb(
  String muscleGroup,
) async {
  final db = await AppDatabases.getDatabase();
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

final exercisesFromAMuscleGroup =
    AsyncNotifierProvider.family<
      ExercisesFromAMuscleGroupNotifier,
      List<Exercise>,
      String
    >(ExercisesFromAMuscleGroupNotifier.new);

class ExercisesFromAMuscleGroupNotifier extends AsyncNotifier<List<Exercise>> {
  ExercisesFromAMuscleGroupNotifier(this.muscleGroup);

  final String muscleGroup;

  @override
  FutureOr<List<Exercise>> build() {
    return _loadAllExercisesInAMuscleGroupFromDb(muscleGroup);
  }

  Future<void> addCustomExercise(Exercise newExercise) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.insert('exercises', {
        'id': newExercise.id,
        'name': newExercise.name,
        'muscle_group': newExercise.muscleGroup,
      });
    });
  }

  Future<void> removeExercise(String exerciseId) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
    });
  }
}
