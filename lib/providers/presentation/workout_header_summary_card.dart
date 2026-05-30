import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/workout_header_summary_card.dart';

FutureOr<WorkoutHeaderSummaryCard?> _loadSummaryInfoFromDb(
  int workoutSessionId,
) async {
  final db = await AppDatabases.getDatabase();

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

  final row = data.first;

  if (row.isEmpty) return null;

  final bool isWorkoutFinished = row['finishedAt'] != null;

  return WorkoutHeaderSummaryCard(
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

final workoutHeaderSummaryCardProvider =
    AsyncNotifierProvider.family<
      WorkoutHeaderSummaryCardNotifier,
      WorkoutHeaderSummaryCard?,
      int
    >(WorkoutHeaderSummaryCardNotifier.new);

class WorkoutHeaderSummaryCardNotifier
    extends AsyncNotifier<WorkoutHeaderSummaryCard?> {
  WorkoutHeaderSummaryCardNotifier(this.workoutSessionId);

  final int workoutSessionId;

  @override
  FutureOr<WorkoutHeaderSummaryCard?> build() {
    return _loadSummaryInfoFromDb(workoutSessionId);
  }
}
