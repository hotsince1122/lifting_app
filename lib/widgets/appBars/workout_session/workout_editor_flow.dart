import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WorkoutEditorFlow {
  const WorkoutEditorFlow();

  String get primaryButtonLabel;

  Future<void> onPrimryAction (
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  );
}