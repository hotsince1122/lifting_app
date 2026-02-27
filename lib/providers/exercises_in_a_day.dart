import 'dart:async';

import 'package:lifting_tracker_app/data/app_databases.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/exercise.dart';

Future<List<Exercise>> _loadExercisesFromADay(
  List<String> exercisesIdsInOrder,
) async {
  if (exercisesIdsInOrder.isEmpty) {
    return [];
  }

  final db = await AppDatabases.getDatabase();

  String placeholders = '';
  for (int i = 0; i < exercisesIdsInOrder.length; i++) {
    placeholders += '?';
    if (i != exercisesIdsInOrder.length - 1) {
      placeholders += ", ";
    }
  }

  final data = await db.query(
    'exercises',
    where: 'id IN ($placeholders)',
    whereArgs: exercisesIdsInOrder,
  );

  final unorderedExercises = data
      .map(
        (row) => Exercise(
          name: row['name'] as String,
          muscleGroup: row['muscle_group'] as String,
          id: row['id'] as String,
        ),
      )
      .toList();

  Map<String, Exercise> dictionary = {};
  for (var exercise in unorderedExercises) {
    dictionary[exercise.id] = exercise;
  }

  final List<Exercise> orderedExercises = [];
  for (var id in exercisesIdsInOrder) {
    if (dictionary[id] == null) {
      continue;
    }

    orderedExercises.add(dictionary[id]!);
  }

  return orderedExercises;
}

//provider diferit pentru chei diferite, practic fiecare exercitiu e atribuit unei zile, al treila camp "List<String>", fiind entry-ul
//pentru fiecare provider, adica id-urile exercitilor dintr-o zi, returnata de day_exercises.db
final exercisesInADayProvider =
    AsyncNotifierProvider.family<
      ExercisesInADayNotifier,
      List<Exercise>,
      List<String>
    >(ExercisesInADayNotifier.new);

class ExercisesInADayNotifier extends AsyncNotifier<List<Exercise>> {
  ExercisesInADayNotifier(this.exercisesIds);

  final List<String> exercisesIds;

  @override
  FutureOr<List<Exercise>> build() {
    return _loadExercisesFromADay(exercisesIds);
  }

  Future<void> addExerciseToDay (String dayId, String exerciseId, int orderIdx) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.insert('day_exercises', {
        'day_id' : dayId,
        'exercise_id' : exerciseId,
        'order_idx' : orderIdx
      });
    });
  }

  Future<void> deleteExerciseFromDay (String dayId, String exerciseId, int orderIdx) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete('day_exercises', where: 'day_id = ? AND  = exercise_id ?', whereArgs: [dayId, exerciseId]);
    });
  }
}
