import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plans_ids.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/delete_flow.dart/delete_flow_contract.dart';

Future<void> _showSplitInUseDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('Split in use'),
        content: const Text(
          'This split is being used by your current workout. '
          'Finish or discard the workout before deleting the split.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class DeleteSplitFlow extends DeleteFlow {
  const DeleteSplitFlow({required this.splitPlanId, required this.ref});

  final int splitPlanId;
  final WidgetRef ref;

  @override
  String get title => 'Delete this split?';

  @override
  String get content =>
      'This will permanently delete the split, its training days, and all exercises scheduled within it. The exercises themselves will remain available.';

  @override
  Future<bool> canShowConfirmation(BuildContext context) async {
    try {
      final hasActiveSession = await ref
          .read(splitPlansIdsProvider.notifier)
          .hasActiveSessionInSplit(splitPlanId);

      if (!hasActiveSession) return true;

      if (context.mounted) {
        await _showSplitInUseDialog(context);
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint('$error');
      debugPrintStack(stackTrace: stackTrace);

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('An error has occurred.'),
              content: const Text('Try again.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Ok'),
                ),
              ],
            );
          },
        );
      }

      return false;
    }
  }

  @override
  Future<void> onDelete(BuildContext context) async {
    try {
      await ref.read(splitPlansIdsProvider.notifier).deletePlan(splitPlanId);
    } catch (error, _) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('An error has occurred.'),
              content: const Text('Try again.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Ok'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}
