import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/rest_timer/application/rest_timer_controller.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/editor/workout_editor_flow.dart';

WorkoutEditorMenuAction buildDeleteWorkoutMenuAction({
  required String confirmationMessage,
  required String errorMessage,
  required String label,
  required Future<void> Function(WidgetRef ref, int id) onDelete,
}) {
  return WorkoutEditorMenuAction(
    label: label,
    icon: Icons.delete,
    tone: ActionTone.destructive,
    onPressed: (context, ref, id) async {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Delete workout?'),
          content: Text(confirmationMessage),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(color: Colors.red),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        await ref.read(restTimerProvider.future);
        if (!context.mounted) return;

        await ref.read(restTimerProvider.notifier).stop();
        if (!context.mounted) return;

        await onDelete(ref, id);
      } catch (_) {
        if (!context.mounted) return;
        SnackBarError.show(context, errorMessage);
        return;
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
    },
  );
}
