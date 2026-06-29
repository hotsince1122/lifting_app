import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WorkoutLaunchFlow {
  const WorkoutLaunchFlow();

  Future<int> startNewSession(WidgetRef ref);
}