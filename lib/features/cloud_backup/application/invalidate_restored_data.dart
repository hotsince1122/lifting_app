import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/exercises/application/exercises_by_muscle_group_controller.dart';
import 'package:lifting_tracker_app/features/history/application/completed_workouts_count_provider.dart';
import 'package:lifting_tracker_app/features/history/application/history_months_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/day_name_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_name_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plans_ids_controller.dart';
import 'package:lifting_tracker_app/features/progress/application/exercise_progress_sets_provider.dart';
import 'package:lifting_tracker_app/features/progress/application/favorite_exercise_ids_controller.dart';
import 'package:lifting_tracker_app/features/progress/application/week_streak_controller.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/workout_name_controller.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/state/workout_header_summary_provider.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';

/// Reloads SQLite-backed state after a successful restore transaction.
void invalidateRestoredData(Ref ref) {
  ref.invalidate(completedWorkoutCountProvider);
  ref.invalidate(historyMonthsProvider);
  ref.invalidate(exerciseProgressSetsProvider);
  ref.invalidate(favoriteExerciseIdsProvider);

  ref.invalidate(activeSplitIdProvider);
  ref.invalidate(splitPlansIdsProvider);
  ref.invalidate(splitPlanProvider);
  ref.invalidate(splitDaysProvider);
  ref.invalidate(splitNameProvider);
  ref.invalidate(dayNameProvider);
  ref.invalidate(plannedExercisesProvider);
  ref.invalidate(exerciseByMuscleGroupProvider);

  ref.invalidate(activeSessionLifecycleProvider);
  ref.invalidate(workoutNameProvider);
  ref.invalidate(workoutSessionExercisesProvider);
  ref.invalidate(workoutHeaderSummaryProvider);
  ref.invalidate(pickedNextSessionProvider);

  ref.invalidate(weeklyWorkoutProgressProvider);
  ref.invalidate(weekStreakProvider);
  ref.invalidate(setupCompletionProvider);
}
