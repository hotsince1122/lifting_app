import 'dart:async';

import 'package:lifting_tracker_app/data/app_databases.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

Future<List<Exercise>> _loadExercisesFromADay(String dayId) async {
  final db = await AppDatabases.getDatabase();

  final rows = await db.rawQuery(
    '''
    SELECT
     e.id AS exercise_id,
     e.name AS name,
     e.muscle_group AS muscle_group,
     de.id AS day_exercise_id
    FROM day_exercises de
    JOIN exercises e ON e.id = de.exercise_id
    WHERE de.day_id = ?
    ORDER BY de.order_idx ASC
  ''',
    [dayId],
  );

  return rows.map((row) {
    return Exercise(
      id: row['exercise_id'] as String,
      name: row['name'] as String,
      muscleGroup: row['muscle_group'] as String,
      idInDayExerciseRelation: row['day_exercise_id'] as int,
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

  Future<void> addExerciseToDay(String dayId, String exerciseId) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
    INSERT INTO day_exercises(day_id, exercise_id, order_idx)
    VALUES (
      ?,
      ?,
      COALESCE((SELECT MAX(order_idx) + 1
       FROM day_exercises
       WHERE day_id = ?),0)
    )
  ''',
        [dayId, exerciseId, dayId],
      );
    });

    state = AsyncData(await _loadExercisesFromADay(dayId));
  }

  Future<void> deleteExerciseFromDay(int idInDayExerciseRelation) async {
    final db = await AppDatabases.getDatabase();

    await db.transaction((txn) async {
      await txn.delete(
        'day_exercises',
        where: 'id = ?',
        whereArgs: [idInDayExerciseRelation],
      );
    });

    state = AsyncData(await _loadExercisesFromADay(dayId));
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final reordered = [...currentState];
    final movedItem = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedItem);

    state = AsyncData(reordered);

    final List<int> ids = [];
    final List<String> caseParts = [];

    for (int i = 0; i < reordered.length; i++) {
      final id = reordered[i].idInDayExerciseRelation!;
      ids.add(id);
      caseParts.add('WHEN $id THEN $i');
    }

    final placeholders = List.filled(ids.length, '?').join(', ');

    final db = await AppDatabases.getDatabase();

    try {
      await db.transaction((txn) async {
        await txn.rawUpdate('''
        UPDATE day_exercises
        SET order_idx = CASE id
          ${caseParts.join('\n          ')}
        END
        WHERE id IN ($placeholders)
        ''', ids);
      });
    } catch (e) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
