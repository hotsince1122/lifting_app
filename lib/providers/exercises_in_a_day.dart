import 'dart:async';

import 'package:lifting_tracker_app/data/app_databases.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/exercise.dart';

Future<List<Exercise>> _loadExercisesFromADay(String dayId) async {
  final db = await AppDatabases.getDatabase();

  final rows = await db.rawQuery('''
    SELECT e.id, e.name, e.muscle_group
    FROM day_exercises de
    JOIN exercises e ON e.id = de.exercise_id
    WHERE de.day_id = ?
    ORDER BY de.order_idx ASC
  ''', [dayId]);

  return rows.map((row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      muscleGroup: row['muscle_group'] as String,
    );
  }).toList();
}

//provider diferit pentru chei diferite, practic fiecare exercitiu e atribuit unei zile, al treila camp "List<String>", fiind entry-ul
//pentru fiecare provider, adica id-urile exercitilor dintr-o zi, returnata de day_exercises.db
final exercisesInADayProvider =
    AsyncNotifierProvider.family<
      ExercisesInADayNotifier,
      List<Exercise>,
      String
    >(ExercisesInADayNotifier.new);

class ExercisesInADayNotifier extends AsyncNotifier<List<Exercise>> {
  ExercisesInADayNotifier(this.dayId);

  final String dayId;

  @override
  FutureOr<List<Exercise>> build() {
    return _loadExercisesFromADay(dayId);
  }

  Future<void> addExerciseToDay(
    String dayId,
    String exerciseId,
    int orderIdx,
  ) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.insert('day_exercises', {
        'day_id': dayId,
        'exercise_id': exerciseId,
        'order_idx': orderIdx,
      });
    });
  }

  Future<void> deleteExerciseFromDay(
    String dayId,
    String exerciseId,
    int orderIdx,
  ) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete(
        'day_exercises',
        where: 'day_id = ? AND  = exercise_id ?',
        whereArgs: [dayId, exerciseId],
      );
    });
  }
}
