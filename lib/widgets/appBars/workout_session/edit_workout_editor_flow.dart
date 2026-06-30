import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/providers/persisted/history_workout_actions.dart';
import 'package:lifting_tracker_app/providers/persisted/workout_name.dart';
import 'package:lifting_tracker_app/screens/workout_editor.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/workout_session_screen/reorder_exercises_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    final workoutNameFromDraft = await ref.read(
      workoutNameProvider(workoutSessionId).future,
    );

    final didSave = await historyWorkoutActionsNotifier.saveEditedWorkout(
      workoutSessionId,
      workoutName: workoutNameFromDraft,
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

  @override
  Future<void> onWorkoutNameChange(
    WidgetRef ref,
    int workoutSessionId,
    String newName,
  ) async {
    ref
        .read(workoutNameProvider(workoutSessionId).notifier)
        .renameDraft(newName);
  }

  @override
  List<WorkoutEditorMenuAction> getMenuActions(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  ) {
    return [
      WorkoutEditorMenuAction(
        label: 'Reorder Exercises',
        icon: Icons.swap_vert_rounded,
        onPressed: (context, ref, id) => ReorderExercisesSheet.openSheet(
          context,
          MediaQuery.of(context).size.width,
          workoutSessionId,
        ),
      ),

      WorkoutEditorMenuAction(
        label: 'Repeat Workout',
        icon: PhosphorIcons.repeat(),
        onPressed: (context, ref, id) async {
          final isSessionAlreadyActive = await ref.read(
            activeSessionLifecycleProvider.future,
          );

          if (isSessionAlreadyActive == true && context.mounted) {
            await showDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text('There is already an active session.'),
                  content: const Text(
                    "You can start only one session at a time.",
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Ok'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );

            return;
          }

          final newWorkoutId = await ref
              .read(activeSessionLifecycleProvider.notifier)
              .startRepeatedWorkout(id);

          if (!context.mounted) return;

          if (newWorkoutId == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Could not repeat this workout.'),
                ),
              );
            return;
          }

          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) Navigator.of(context).pop();

          if (context.mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutEditorScreen.active(newWorkoutId),
              ),
            );
          }
        },
      ),
    ];
  }
}
