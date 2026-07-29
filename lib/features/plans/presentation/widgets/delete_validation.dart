import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/delete_flow/delete_flow_contract.dart';

Future<bool> showDeleteValidation(
  BuildContext context,
  DeleteFlow deleteFlow,
) async {
  final canShowConfirmation = await deleteFlow.canShowConfirmation(context);

  if (!canShowConfirmation || !context.mounted) return false;

  final confirmed = await showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(deleteFlow.title),
        content: Text(deleteFlow.content),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    await deleteFlow.onDelete(context);
  } catch (_) {
    if (context.mounted) {
      SnackBarError.show(context, 'Could not delete. Try again!');
    }
    return false;
  }

  return true;
}
