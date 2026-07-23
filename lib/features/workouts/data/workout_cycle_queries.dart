import 'package:lifting_tracker_app/core/utils/build_placeholder_for_sqlite.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:sqflite/sqflite.dart';

Future<int> loadNextCycleIndex(
  Database db,
  List<String> activeSplitDaysIds,
) async {
  final placeholder = buildPlaceholder(activeSplitDaysIds.length);

  final data = await db.rawQuery(
    '''
    SELECT cycle_index
    FROM workout_sessions
    WHERE day_id IN ($placeholder)
      AND status = ?
      AND finished_at IS NOT NULL
    ORDER BY finished_at DESC
    LIMIT 1
    ''',
    [...activeSplitDaysIds, WorkoutSessionStatuses.completedStatus],
  );

  if (data.isEmpty) return 0;

  return ((data.first['cycle_index'] as int) + 1) % activeSplitDaysIds.length;
}