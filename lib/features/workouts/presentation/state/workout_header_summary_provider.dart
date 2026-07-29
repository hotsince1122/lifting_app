import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/workouts/presentation/view_data/workout_header_summary_view_data.dart';

FutureOr<WorkoutHeaderSummaryViewData?> _loadSummaryInfoFromDb(
  int workoutSessionId,
) async {
  final summary = await queries.loadWorkoutSessionSummary(workoutSessionId);
  if (summary == null) return null;

  final isWorkoutFinished = summary.finishedAt != null;

  return WorkoutHeaderSummaryViewData(
    workoutName: summary.workoutName,
    startTime: summary.startedAt,
    endTime: summary.finishedAt,
    workoutDurationInMinutes: isWorkoutFinished
        ? transformSecondsToMinutes(summary.durationSeconds!)
        : null,
  );
}

int transformSecondsToMinutes(int seconds) {
  return (seconds / 60).toInt();
}

final workoutHeaderSummaryProvider = FutureProvider.autoDispose
    .family<WorkoutHeaderSummaryViewData?, int>(
      (ref, workoutSessionId) => _loadSummaryInfoFromDb(workoutSessionId),
    );
