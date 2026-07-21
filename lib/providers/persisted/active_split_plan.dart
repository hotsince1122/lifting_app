import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/custom_split.dart';
import 'package:lifting_tracker_app/models/entity/split_plan.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_id.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';

final activeSplitPlanProvider =
    AsyncNotifierProvider<ActiveSplitPlanNotifier, SplitPlan?>(
      ActiveSplitPlanNotifier.new,
    );

class ActiveSplitPlanNotifier extends AsyncNotifier<SplitPlan?> {
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
    return ref
        .read(activeSplitIdProvider.notifier)
        .changeToExisting(splitId);
  }
}
