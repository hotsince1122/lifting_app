import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/history/data/workout_summary_history_queries.dart';

final completedWorkoutCountProvider = FutureProvider<int>((ref) {
  return loadAllCompletedWorkoutsCount();
});
