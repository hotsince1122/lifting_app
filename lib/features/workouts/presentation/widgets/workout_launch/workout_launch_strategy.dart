import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WorkoutLaunchStrategy {
  const WorkoutLaunchStrategy();

  Future<int> startNewSession(WidgetRef ref);
}
