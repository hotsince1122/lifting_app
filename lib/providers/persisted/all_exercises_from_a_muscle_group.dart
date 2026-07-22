import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

Future<List<Exercise>> _loadAllExercisesInAMuscleGroupFromDb(
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

  Future<Exercise> addCustomExercise(String name, String muscleGroup) async {
    final db = await AppDatabase.getDatabase();
    final newExercise = Exercise(name: name, muscleGroup: muscleGroup);

    await db.transaction((txn) async {
      await txn.insert('exercises', {
        'id': newExercise.id,
        'name': newExercise.name,
        'muscle_group': newExercise.muscleGroup,
      });
    });

    state = AsyncData(
      await _loadAllExercisesInAMuscleGroupFromDb(this.muscleGroup),
    );
    return newExercise;
  }

  Future<void> updateExercise(
    Exercise exercise,
    String name,
    String muscleGroup,
  ) async {
    final db = await AppDatabase.getDatabase();

    final updatedExercise = exercise.copyWith(
      name: name,
      muscleGroup: muscleGroup,
    );

    await db.transaction((txn) async {
      await txn.update(
        'exercises',
        {
          'name': updatedExercise.name,
          'muscle_group': updatedExercise.muscleGroup,
        },
        where: 'id = ?',
        whereArgs: [exercise.id],
      );
    });

    state = AsyncData(await _loadAllExercisesInAMuscleGroupFromDb(muscleGroup));
  }

  Future<void> removeExercise(String exerciseId) async {
    final db = await AppDatabase.getDatabase();

    await db.transaction((txn) async {
      await txn.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
    });

    state = AsyncData(await _loadAllExercisesInAMuscleGroupFromDb(muscleGroup));
  }
}
