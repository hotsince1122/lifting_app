import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/history/application/history_months_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_plan.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/invalidate_restored_data.dart';

class _TestActiveSplitIdController extends ActiveSplitIdController {
  _TestActiveSplitIdController(this.onBuild);

  final int? Function() onBuild;

  @override
  FutureOr<int?> build() => onBuild();
}

void main() {
  test('reloads history and the active split after restore', () async {
    var historyReads = 0;
    var splitReads = 0;
    var planReads = 0;
    var activeSplitId = 1;
    var planName = 'Old plan';
    final container = ProviderContainer.test(
      overrides: [
        historyMonthsProvider.overrideWith((ref) async {
          historyReads++;
          return [];
        }),
        activeSplitIdProvider.overrideWith(
          () => _TestActiveSplitIdController(() {
            splitReads++;
            return activeSplitId;
          }),
        ),
        splitPlanProvider(1).overrideWith((ref) async {
          planReads++;
          return SplitPlan(
            id: 1,
            name: planName,
            isPreset: false,
            isActive: true,
            cycleLengthInDays: 1,
            exerciseCount: 1,
          );
        }),
      ],
    );
    await container.read(historyMonthsProvider.future);
    expect(await container.read(activeSplitIdProvider.future), 1);
    expect(
      (await container.read(splitPlanProvider(1).future))?.name,
      'Old plan',
    );

    activeSplitId = 2;
    planName = 'Restored plan';
    container.read(Provider<void>((ref) => invalidateRestoredData(ref)));

    await container.read(historyMonthsProvider.future);
    expect(await container.read(activeSplitIdProvider.future), 2);
    expect(
      (await container.read(splitPlanProvider(1).future))?.name,
      'Restored plan',
    );
    expect(historyReads, 2);
    expect(splitReads, 2);
    expect(planReads, 2);
  });
}
