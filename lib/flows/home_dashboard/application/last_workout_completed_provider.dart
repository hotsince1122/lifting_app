import 'package:lifting_tracker_app/features/history/application/history_months_provider.dart';
import 'package:lifting_tracker_app/features/history/domain/last_completed_workout_summary.dart';
import 'package:riverpod/riverpod.dart';

import 'package:lifting_tracker_app/features/history/data/workout_summary_history_queries.dart'
    as queries;

final lastWorkoutCompletedProvider =
    FutureProvider<LastCompletedWorkoutSummary?>((ref) async {
      ref.watch(historyMonthsProvider);
      return queries.loadLastCompletedWorkoutSummary();
    });
