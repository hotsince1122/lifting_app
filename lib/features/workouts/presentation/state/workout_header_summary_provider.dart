import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/view_data/workout_header_summary_view_data.dart';

FutureOr<WorkoutHeaderSummaryViewData?> _loadSummaryInfoFromDb(
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  var data = await db.rawQuery(
    '''
  SELECT ws.workout_name AS workoutName, 
    ws.started_at AS startedAt,
    ws.finished_at AS finishedAt,
    ws.duration_seconds AS durationSeconds
  FROM workout_sessions ws
  WHERE ws.id = ?
  ''',
    [workoutSessionId],
  );

  if (data.isEmpty) return null;

  final row = data.first;

  if (row.isEmpty) return null;

  final bool isWorkoutFinished = row['finishedAt'] != null;

  return WorkoutHeaderSummaryViewData(
    workoutName: row['workoutName'] as String,
    startTime: DateTime.fromMillisecondsSinceEpoch(
      (row['startedAt'] as int) * 1000,
    ),
    endTime: isWorkoutFinished
        ? DateTime.fromMillisecondsSinceEpoch((row['finishedAt'] as int) * 1000)
        : null,
    workoutDurationInMinutes: isWorkoutFinished
        ? transformSecondsToMinutes(row['durationSeconds'] as int)
        : null,
  );
}

int transformSecondsToMinutes(int seconds) {
  return (seconds / 60).toInt();
}

final workoutHeaderSummaryProvider =
    FutureProvider.family<WorkoutHeaderSummaryViewData?, int>(
      (ref, workoutSessionId) => _loadSummaryInfoFromDb(workoutSessionId),
    );
