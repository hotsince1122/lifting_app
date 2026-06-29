import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WorkoutEditorFlow {
  const WorkoutEditorFlow();

  String get primaryButtonLabel;

  Future<void> onPrimaryAction(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  );

  Future<void> onWorkoutNameChange(
    WidgetRef ref,
    int workoutSessionId,
    String newName,
  );
}
