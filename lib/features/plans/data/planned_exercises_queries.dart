import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/plans/domain/planned_exercise.dart';

Future<List<PlannedExercise>> loadPlannedExercises(String dayId) async {
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