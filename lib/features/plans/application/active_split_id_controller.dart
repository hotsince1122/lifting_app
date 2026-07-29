import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/domain/custom_split.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plans_ids_controller.dart';

import 'package:lifting_tracker_app/features/plans/data/split_plan_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/plans/data/split_plan_commands.dart'
    as commands;

final activeSplitIdProvider =
    AsyncNotifierProvider<ActiveSplitIdController, int?>(
      ActiveSplitIdController.new,
    );

class ActiveSplitIdController extends AsyncNotifier<int?> {
  @override
  FutureOr<int?> build() {
    return queries.loadActiveSplitId();
  }

  Future<void> addAndChangeToCustom(CustomSplit newSplit) async {
    final previousSplitId = state.value;

    final newSplitPlanId = await commands.addAndChangeToCustom(newSplit);

    if (previousSplitId != null) {
      ref.invalidate(splitPlanProvider(previousSplitId));
    }
    ref.invalidate(splitPlanProvider(newSplitPlanId));
    ref.invalidate(splitPlansIdsProvider);

    state = AsyncData(newSplitPlanId);
  }

  Future<void> changeToExisting(int splitId) async {
    final previousSplitId = state.value;

    await commands.changeToExisting(splitId);

    if (previousSplitId != null) {
      ref.invalidate(splitPlanProvider(previousSplitId));
    }
    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(splitPlansIdsProvider);

    state = AsyncData(splitId);
  }
}
