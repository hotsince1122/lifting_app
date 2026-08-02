import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/history/application/history_workout_actions_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/workout_name_controller.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/pages/workout_editor_page.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/editor/workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/reorder_exercises_sheet.dart';
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

    try {
      await historyWorkoutActionsNotifier.saveEditedWorkout(
        workoutSessionId,
        workoutName: workoutNameFromDraft,
      );
    } catch (_, _) {
      if (!context.mounted) return;
      SnackBarError.show(context, 'Could not save changes. Please try again.');
      return;
    }

    if (!context.mounted) return;
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
        onPressed: (context, ref, id) =>
            ReorderExercisesSheet.openSheet(context, workoutSessionId),
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

          late final int newWorkoutId;

          try {
            newWorkoutId = await ref
                .read(activeSessionLifecycleProvider.notifier)
                .startRepeatedWorkout(id);
          } catch (_) {
            if (!context.mounted) return;
            SnackBarError.show(
              context,
              'Could not repeat this workout. Please try again.',
            );
            return;
          }

          if (!context.mounted) return;

          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) Navigator.of(context).pop();

          if (context.mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutEditorPage.active(newWorkoutId),
              ),
            );
          }
        },
      ),
    ];
  }
}
