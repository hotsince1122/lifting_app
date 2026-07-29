import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/delete/delete_flow/delete_flow_contract.dart';

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
    await ref.read(splitDaysProvider(splitId).notifier).deleteSplitDay(dayId);
  }
}
