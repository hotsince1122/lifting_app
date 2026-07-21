import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/delete_flow.dart/delete_flow_contract.dart';

class DeleteDayFlow extends DeleteFlow {
  const DeleteDayFlow({
    required this.splitId,
    required this.dayId,
    required this.ref,
  });

  final int splitId;
  final String dayId;
  final WidgetRef ref;

  @override
  String get title => 'Delete training day?';

  @override
  String get content =>
      'This will remove the day and all exercises scheduled for it from this split. The exercises themselves will not be deleted.';

  @override
  Future<void> onDelete(BuildContext context) async {
    try {
      await ref.read(splitDaysProvider(splitId).notifier).deleteSplitDay(dayId);
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
