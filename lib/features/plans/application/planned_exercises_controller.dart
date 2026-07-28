import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/plans/domain/planned_exercise.dart';

Future<List<PlannedExercise>> _loadPlannedExercises(String dayId) async {
  final db = await AppDatabase.getDatabase();

  final rows = await db.rawQuery(
    '''
    SELECT
      e.id AS exercise_id,
      e.name AS name,
      e.muscle_group AS muscle_group,
      de.id AS relation_id,
      de.order_idx AS order_index
    FROM day_exercises de
    JOIN exercises e ON e.id = de.exercise_id
    WHERE de.day_id = ?
    ORDER BY de.order_idx ASC
    ''',
    [dayId],
  );

  return rows.map((row) {
    return PlannedExercise(
      catalogExercise: CatalogExercise(
        id: row['exercise_id'] as String,
        name: row['name'] as String,
        muscleGroup: row['muscle_group'] as String,
      ),
      relationId: row['relation_id'] as int,
      orderIndex: row['order_index'] as int,
    );
  }).toList();
}

final plannedExercisesProvider =
    AsyncNotifierProvider.family<
      PlannedExercisesController,
      List<PlannedExercise>,
      String
    >(PlannedExercisesController.new);

class PlannedExercisesController extends AsyncNotifier<List<PlannedExercise>> {
  PlannedExercisesController(this.dayId);

  final String dayId;

  @override
  FutureOr<List<PlannedExercise>> build() {
    return _loadPlannedExercises(dayId);
  }

  Future<void> addExerciseToDay(String exerciseId) async {
    final db = await AppDatabase.getDatabase();

    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
        INSERT INTO day_exercises(day_id, exercise_id, order_idx)
        VALUES (
          ?,
          ?,
          COALESCE((
            SELECT MAX(order_idx) + 1
            FROM day_exercises
            WHERE day_id = ?
          ), 0)
        )
        ''',
        [dayId, exerciseId, dayId],
      );
    });

    state = AsyncData(await _loadPlannedExercises(dayId));
  }

  Future<void> deleteExerciseFromDay(int relationId) async {
    final db = await AppDatabase.getDatabase();

    await db.transaction((txn) async {
      await txn.delete(
        'day_exercises',
        where: 'id = ?',
        whereArgs: [relationId],
      );
    });

    state = AsyncData(await _loadPlannedExercises(dayId));
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    if (newIndex > oldIndex) newIndex--;

    final reordered = [...currentState];
    final movedItem = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedItem);

    final normalized = [
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(orderIndex: i),
    ];

    state = AsyncData(normalized);

    final ids = normalized.map((exercise) => exercise.relationId).toList();
    final caseParts = <String>[
      for (int i = 0; i < normalized.length; i++)
        'WHEN ${normalized[i].relationId} THEN $i',
    ];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final db = await AppDatabase.getDatabase();

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
    } catch (_) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
