import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/split_plan.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/preset_split_vm.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';

class PresetSplits extends ConsumerWidget {
  const PresetSplits({
    super.key,
    required this.currentSplit,
  });

  final SplitPlan? currentSplit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final presetSplitVmAsync = ref.watch(presetSplitVmProvider);

    return presetSplitVmAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured. Try again.')),
      data: (presetSplitVm) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            for (final preset in presetSplitVm)
              GradientButton(
                gradientVariant: _gradientForSplit(preset.splitId),
                isActive: currentSplit != null && preset.splitId == currentSplit!.id,
                onPressed: () => ref.read(activeSplitPlanProvider.notifier).changeToExisting(preset.splitId),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          preset.splitPlanName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${preset.nrOfDays}-day cycle',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.accentLightGray),
                        ),
                      ],
                    ),
                    Text(
                      preset.splitDaysNames,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

LinearGradient _gradientForSplit(int splitId) {
  const variants = [
    AppGradients.darkOne,
    AppGradients.darkTwo,
    AppGradients.darkThree,
  ];

  return Gradients.of(variants[(splitId - 1) % variants.length]);
}
