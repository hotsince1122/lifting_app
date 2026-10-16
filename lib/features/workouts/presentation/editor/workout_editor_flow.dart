import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

enum ActionTone { standard, destructive }

class WorkoutEditorMenuAction {
  const WorkoutEditorMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = ActionTone.standard,
  });

  final String label;
  final IconData icon;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  )
  onPressed;
  final ActionTone tone;
  Color get color => tone == ActionTone.standard ? AppColors.onSurface : Colors.red;
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
