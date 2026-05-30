import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/history_workout_actions.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';

class EditWorkoutEditorFlow extends WorkoutEditorFlow {
  const EditWorkoutEditorFlow();

  @override
  String get primaryButtonLabel => 'Save';

  @override
  Future<void> onPrimaryAction(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  ) async {
    final historyWorkoutActionsNotifier = ref.read(
      historyWorkoutActionsProvider.notifier,
    );

    final didSave = await historyWorkoutActionsNotifier.saveEditedWorkout(
      workoutSessionId,
    );

    if (!context.mounted) return;

    if (!didSave) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save changes. Please try again.'),
          ),
        );
      return;
    }

    Navigator.of(context).pop();
  }
}
