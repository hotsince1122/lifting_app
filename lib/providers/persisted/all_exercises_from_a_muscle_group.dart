import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

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

  Future<bool> validateExercise(String? name, String? muscleGroup, BuildContext context) async {
    if (name == null || name.trim().isEmpty || muscleGroup == null) {
      await showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Name or muscle group empty'),
            content: const Text("Name and muscle group can't be empty."),
            actions: [
              CupertinoDialogAction(
                child: const Text('Ok'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      return false;
    }
    return true;
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

  Future<Exercise?> addCustomExercise(String? name, String? muscleGroup, BuildContext context) async {
    final db = await AppDatabases.getDatabase();

    if(!context.mounted) return null;
    bool isValid = await validateExercise(name, muscleGroup, context);
    if (isValid == false) return null;

    await db.transaction((txn) async {
      await txn.insert('exercises', {
        'name': name,
        'muscle_group': muscleGroup,
      });
    });

    state = AsyncData(await _loadAllExercisesInAMuscleGroupFromDb(muscleGroup!));
    return Exercise(name: name!, muscleGroup: muscleGroup);
  }

  Future<void> updateExercise(Exercise? editingExercise, String? newName, String? newMuscleGroup, BuildContext context) async {
    final db = await AppDatabases.getDatabase();

    final exercise = editingExercise;
    if (exercise == null) return;

    if(!context.mounted) return;
    bool isValid = await validateExercise(newName, muscleGroup, context);
    if (isValid == false) return;

    final updatedExercise = exercise.copyWith(
      name: newName!.trim(),
      muscleGroup: newMuscleGroup!,
    );

    await db.transaction((txn) async {
      await txn.update(
        'exercises',
        {'name': updatedExercise.name, 'muscle_group': updatedExercise.muscleGroup},
        where: 'id = ?',
        whereArgs: [exercise.id],
      );
    });

    state = AsyncData(await _loadAllExercisesInAMuscleGroupFromDb(muscleGroup));
  }

  Future<void> removeExercise(String exerciseId) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
    });

    state = AsyncData(await _loadAllExercisesInAMuscleGroupFromDb(muscleGroup));
  }
}