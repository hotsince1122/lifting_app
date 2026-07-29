import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/buttons/gradient_button.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_plan_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_plan.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/state/preset_split_view_data_provider.dart';

class PresetSplits extends ConsumerWidget {
  const PresetSplits({super.key, required this.currentSplit});

  final SplitPlan? currentSplit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetSplitVmAsync = ref.watch(presetSplitViewDataProvider);

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
                gradientVariant: AppGradients.card,
                isActive:
                    currentSplit != null && preset.splitId == currentSplit!.id,
                onPressed: () async {
                  try {
                    await ref
                        .read(activeSplitPlanProvider.notifier)
                        .changeToExisting(preset.splitId);
                  } catch (_) {
                    if (!context.mounted) return;
                    SnackBarError.show(
                      context,
                      'Could not activate split. Try again!',
                    );
                  }
                },
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
                          '${preset.dayCount}-day cycle',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                    Text(
                      preset.splitDaysNames,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.secondary,
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
