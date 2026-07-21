import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/delete_flow.dart/delete_flow_contract.dart';

Future<void> showDeleteValidation(
  BuildContext context,
  DeleteFlow deleteFlow,
) async {
  final canShowConfirmation = await deleteFlow.canShowConfirmation(context);

  if (!canShowConfirmation || !context.mounted) return;

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

  if (confirmed != true || !context.mounted) return;

  await deleteFlow.onDelete(context);
}