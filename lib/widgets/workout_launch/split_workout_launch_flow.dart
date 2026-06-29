import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/widgets/workout_launch/workout_launch_flow.dart';

class SplitWorkoutLaunchFlow extends WorkoutLaunchFlow {
  const SplitWorkoutLaunchFlow();

  @override
  Future<int> startNewSession(WidgetRef ref) {
    return ref.read(activeSessionLifecycleProvider.notifier).startSession();
  }
}
