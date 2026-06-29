import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/widgets/workout_launch/workout_launch_flow.dart';

class QuickWorkoutLaunchFlow extends WorkoutLaunchFlow {
  const QuickWorkoutLaunchFlow();

  @override
  Future<int> startNewSession(WidgetRef ref) {
    return ref
        .read(activeSessionLifecycleProvider.notifier)
        .startQuickWorkout();
  }
}
