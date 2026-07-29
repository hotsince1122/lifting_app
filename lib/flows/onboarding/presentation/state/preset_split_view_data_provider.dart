import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plans_ids_controller.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/view_data/preset_split_plans_card_view_data.dart';

final presetSplitViewDataProvider =
    FutureProvider<List<PresetSplitPlanCardViewData>>((ref) async {
      final splitIds = [...await ref.watch(splitPlansIdsProvider.future)]
        ..sort();
      final presetViewData = <PresetSplitPlanCardViewData>[];

      for (final splitId in splitIds) {
        final splitPlan = await ref.watch(splitPlanProvider(splitId).future);
        if (splitPlan == null || !splitPlan.isPreset) continue;

        final splitDays = await ref.watch(splitDaysProvider(splitId).future);
        presetViewData.add(
          PresetSplitPlanCardViewData(
            splitId: splitId,
            splitPlanName: splitPlan.name,
            splitDaysNames: splitDays.map((day) => day.name).join(' / '),
            dayCount: splitDays.length,
          ),
        );
      }

      return presetViewData;
    });
