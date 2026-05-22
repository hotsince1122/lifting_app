import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';

class EditWorkoutEditorFlow extends WorkoutEditorFlow {
  const EditWorkoutEditorFlow();

  @override
  String get primaryButtonLabel => 'Save';

  @override
  Future<void> onPrimryAction(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId
  ) async {
    //rescriem logged_sets din active_session_sets

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}