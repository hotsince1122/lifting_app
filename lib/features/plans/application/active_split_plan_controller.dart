import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/domain/custom_split.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_plan.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';

final activeSplitPlanProvider =
    AsyncNotifierProvider<ActiveSplitPlanController, SplitPlan?>(
      ActiveSplitPlanController.new,
    );

class ActiveSplitPlanController extends AsyncNotifier<SplitPlan?> {
  @override
  FutureOr<SplitPlan?> build() async {
    final activeSplitId = await ref.watch(activeSplitIdProvider.future);

    if (activeSplitId == null) return null;

    return ref.watch(splitPlanProvider(activeSplitId).future);
  }

  Future<void> addAndChangeToCustom(CustomSplit newSplit) {
    return ref
        .read(activeSplitIdProvider.notifier)
        .addAndChangeToCustom(newSplit);
  }

  Future<void> changeToExisting(int splitId) {
    return ref.read(activeSplitIdProvider.notifier).changeToExisting(splitId);
  }
}
