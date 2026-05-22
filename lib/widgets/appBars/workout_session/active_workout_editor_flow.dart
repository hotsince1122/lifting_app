import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';

class ActiveWorkoutEditorFlow extends WorkoutEditorFlow {
  const ActiveWorkoutEditorFlow();

  Future<void> _handleFinish(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  ) async {
    final sessionStatusNotifier = ref.read(
      currentSessionStatusProvider.notifier,
    );

    final hasEmptySet = await sessionStatusNotifier.checkIfAnySetEmpty(
      workoutSessionId,
    );

    final userModifiedPlannedExercises = await sessionStatusNotifier
        .checkIfUserModifiedExercisesPlanned(workoutSessionId);

    if (hasEmptySet && context.mounted) {
      await _handleEmptySets(context, sessionStatusNotifier, workoutSessionId);
    }

    if (userModifiedPlannedExercises && context.mounted) {
      await _handleUpdatePlan(context, sessionStatusNotifier, workoutSessionId);
    }

    await sessionStatusNotifier.endSession(workoutSessionId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleEmptySets(
    BuildContext context,
    CurrentSessionStatusNotifier sessionStatusNotifier,
    int workoutSessionId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Weight or reps missing'),
          content: const Text(
            'Do you want to autofill them using last time weight and reps?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Yes, Autofill'),
              onPressed: () async {
                await sessionStatusNotifier.saveEmptySetsWithHints(
                  workoutSessionId,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('No Thanks'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpdatePlan(
    BuildContext context,
    CurrentSessionStatusNotifier sessionStatusNotifier,
    int workoutSessionId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Update plan?'),
          content: const Text(
            'You changed the exercises in this session. Save this order and exercise list for future sessions?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Update plan'),
              onPressed: () async {
                await sessionStatusNotifier.updateCurrentPlan(workoutSessionId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('This session only'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  String get primaryButtonLabel => 'Finish';

  @override
  Future<void> onPrimryAction(
    BuildContext context,
    WidgetRef ref,
    int workoutSessionId,
  ) async {
    _handleFinish(context, ref, workoutSessionId);
  }
}
