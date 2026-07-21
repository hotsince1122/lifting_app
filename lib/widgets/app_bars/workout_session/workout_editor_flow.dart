import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutEditorMenuAction {
  const WorkoutEditorMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed
  });

  final String label;
  final IconData icon;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  ) onPressed;
}

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

  List<WorkoutEditorMenuAction> getMenuActions(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  );
}
