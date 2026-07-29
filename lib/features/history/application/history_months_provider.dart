import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/history/presentation/view_data/history_month_view_data.dart';
import 'package:lifting_tracker_app/features/history/data/workout_summary_history_queries.dart'
    as queries;

final historyMonthsProvider = FutureProvider<List<HistoryMonthViewData>>((ref) {
  ref.watch(activeSessionLifecycleProvider);
  return loadHistoryMonths();
});

Future<List<HistoryMonthViewData>> loadHistoryMonths() async {
  final workoutsByMonth = await queries.loadHistoryMonths();

  return workoutsByMonth.entries
      .map(
        (entry) => HistoryMonthViewData(
          year: entry.key.year,
          month: entry.key.month,
          workoutCount: entry.value.length,
          workouts: entry.value,
        ),
      )
      .toList();
}
