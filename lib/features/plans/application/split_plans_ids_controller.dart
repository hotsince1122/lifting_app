import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_name_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_day_summary_controller.dart';

import 'package:lifting_tracker_app/features/plans/data/split_plan_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/plans/data/split_plan_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/plans/domain/delete_split_plan_result.dart';

final splitPlansIdsProvider =
    AsyncNotifierProvider<SplitPlansIdsController, List<int>>(
      SplitPlansIdsController.new,
    );

class SplitPlansIdsController extends AsyncNotifier<List<int>> {
  @override
  FutureOr<List<int>> build() {
    return queries.loadSplitPlanIds();
  }

  Future<DeleteSplitPlanResult> deletePlan(int splitId) async {
    final result = await commands.deletePlan(splitId);

    if (result == DeleteSplitPlanResult.sessionInSplitActive) {
      return DeleteSplitPlanResult.sessionInSplitActive;
    }

    final currentIds = state.value;
    state = AsyncData(
      currentIds == null
          ? await queries.loadSplitPlanIds()
          : currentIds.where((id) => id != splitId).toList(),
    );

    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(splitNameProvider(splitId));
    ref.invalidate(splitDaysProvider(splitId));
    ref.invalidate(splitDaySummaryProvider);

    return DeleteSplitPlanResult.success;
  }

  Future<bool> hasActiveSessionInSplit(int splitId) async {
    return await queries.hasActiveSessionInSplit(splitId);
  }
}
