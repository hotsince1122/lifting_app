import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';

import 'package:lifting_tracker_app/features/plans/data/split_plan_queries.dart'
    as queries;

import 'package:lifting_tracker_app/features/plans/data/split_plan_commands.dart'
    as commands;

final splitNameProvider = AsyncNotifierProvider.autoDispose
    .family<SplitNameController, String, int>(SplitNameController.new);

class SplitNameController extends AsyncNotifier<String> {
  SplitNameController(this.splitId);

  final int splitId;

  @override
  Future<String> build() async {
    return queries.loadSplitName(splitId);
  }

  Future<void> renameSplit(String newName) async {
    await commands.renameSplit(newName, splitId);

    ref.invalidate(splitPlanProvider(splitId));

    state = AsyncData(newName);
  }
}
