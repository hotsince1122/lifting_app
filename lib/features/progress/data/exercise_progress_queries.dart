import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/progress/domain/exercise_progress_set.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';

Future<List<ExerciseProgressSet>> loadExerciseProgressSets(
  String exerciseId,
) async {
  final db = await AppDatabase.getDatabase();

  final setsData = await db.rawQuery(
    '''
    SELECT ls.id AS setId,
      ws.id AS sessionId,
      ws.started_at AS sessionStartedAt,
      ls.order_index AS exerciseOrderIndex,
      ls.set_index AS setIndex,
      ls.weight AS weight,
      ls.repetitions AS repetitions
    FROM logged_sets AS ls
    JOIN workout_sessions AS ws ON ls.session_id = ws.id
    WHERE ls.ex_id = ?
      AND ws.status = ?
      AND ws.finished_at IS NOT NULL
      AND ls.is_warmup = 0
    ORDER BY ws.started_at, ws.id, ls.order_index, ls.set_index, ls.id
    ''',
    [exerciseId, WorkoutSessionStatuses.completedStatus],
  );

  return setsData
      .map(
        (row) => ExerciseProgressSet(
          setId: row['setId'] as int,
          sessionId: row['sessionId'] as int,
          sessionStartedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['sessionStartedAt'] as int) * 1000,
          ),
          exerciseOrderIndex: row['exerciseOrderIndex'] as int,
          setIndex: row['setIndex'] as int,
          weight: (row['weight'] as num).toDouble(),
          repetitions: row['repetitions'] as int,
        ),
      )
      .toList();
}

Future<bool> loadIfExerciseHasHistory(String exerciseId) async {
  final db = await AppDatabase.getDatabase();

  final setData = await db.rawQuery(
    '''
    SELECT id
    FROM logged_sets
    WHERE ex_id = ?
    ''',
    [exerciseId],
  );

  return setData.isNotEmpty;
}
