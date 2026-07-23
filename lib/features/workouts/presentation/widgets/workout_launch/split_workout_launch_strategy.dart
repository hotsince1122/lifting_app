import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_launch/workout_launch_strategy.dart';

class SplitWorkoutLaunchStrategy extends WorkoutLaunchStrategy {
  const SplitWorkoutLaunchStrategy();

  @override
  Future<int> startNewSession(WidgetRef ref) {
    return ref.read(activeSessionLifecycleProvider.notifier).startSession();
  }
}
