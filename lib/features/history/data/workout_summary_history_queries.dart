import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/history/presentation/view_data/history_workout_view_data.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';

Future<List<String>> _loadWorkoutExerciseLabels(int workoutId) async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
    SELECT e.name AS exerciseName, COUNT(*) as exerciseSets
    FROM logged_sets ls
    JOIN exercises e ON ls.ex_id = e.id
    WHERE session_id = ?
    GROUP BY ls.ex_id, ls.order_index
    ORDER BY ls.order_index
    ''',
    [workoutId],
  );

  if (data.isEmpty) return [];

  final exercisesLabels = <String>[];

  for (final exercise in data) {
    exercisesLabels.add(
      '${exercise['exerciseSets']}x ${exercise['exerciseName']}',
    );
  }

  return exercisesLabels;
}

Future<Map<DateTime, List<HistoryWorkoutViewData>>> loadHistoryMonths() async {
  final db = await AppDatabase.getDatabase();
  final rows = await db.rawQuery(
    '''
      SELECT id,
        workout_name AS workoutName,
        started_at AS startedAt,
        duration_seconds AS durationSeconds
      FROM workout_sessions
      WHERE status = ?
        AND finished_at IS NOT NULL
      ORDER BY finished_at DESC
      ''',
    [WorkoutSessionStatuses.completedStatus],
  );

  final workoutsByMonth = <DateTime, List<HistoryWorkoutViewData>>{};

  for (final row in rows) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      (row['startedAt'] as int) * 1000,
    );
    final monthKey = DateTime(startedAt.year, startedAt.month);

    workoutsByMonth
        .putIfAbsent(monthKey, () => [])
        .add(
          HistoryWorkoutViewData(
            workoutId: row['id'] as int,
            workoutName: row['workoutName'] as String,
            startedAt: startedAt,
            durationSeconds: row['durationSeconds'] as int,
            exercisesLabel: await _loadWorkoutExerciseLabels(row['id'] as int),
          ),
        );
  }

  return workoutsByMonth;
}
