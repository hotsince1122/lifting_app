import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:animations/animations.dart';

import 'package:lifting_tracker_app/models/gradient_variants.dart';
import 'package:lifting_tracker_app/models/split_days.dart';
import 'package:lifting_tracker_app/providers/split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/custom_split_selector.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class SelectSplitPage extends ConsumerWidget {
  const SelectSplitPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<List<SplitDay>?> openCustomSplitSelector(
      BuildContext context,
      double screenWidth,
    ) {
      return showModalBottomSheet<List<SplitDay>>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black38,
        isScrollControlled: true,
        builder: (ctx) => CustomSplitSelector(screenWidth: screenWidth),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final splitPlanAsync = ref.watch(splitPlanProvider);

    return splitPlanAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (splitPlan) {
        void onSelect(List<SplitDay> newSplit) {
          ref.read(splitPlanProvider.notifier).changeSplit(newSplit);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: Gradients.of(GradientVariant.darkThree),
                child: Column(
                  children: [
                    Text(
                      "Let's set up your traning split:",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8,),
                    Text(
                      "You can change it later.",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Presets:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              //Preset Splits Buttons
              PresetSplits(onSelect: onSelect, currentSplit: splitPlan),

              const SizedBox(height: 16),

              //Divider Custom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: const Divider(
                        color: AppColors.bgSecondary,
                        thickness: 1.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Or',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: const Divider(
                        color: AppColors.bgSecondary,
                        thickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              //Custom Split button
              GradientButton(
                isActive:
                    (splitPlan.isNotEmpty &&
                    splitPlan.any(
                      (splitDay) => splitDay.selectedPreset == null,
                    )),
                onPressed: () async {
                  final List<SplitDay>? customSplit =
                      await openCustomSplitSelector(context, screenWidth);
                  if (customSplit != null) {
                    onSelect(customSplit);
                  }
                },
                gradientVariant: Gradients.of(GradientVariant.darkOne),
                buttonWidth: screenWidth - 172,
                buttonHight: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.accentLightGray,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Creat Custom Split',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Build your own schedule.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue.withAlpha(180),
                ),
              ),
              const Spacer(),
              GradientButton(
                isActive: false,
                buttonHight: 48,
                onPressed: splitPlan.isEmpty
                    ? () {}
                    : () => controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      ),
                gradientVariant: Gradients.of(GradientVariant.lightOne),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PresetSplits extends StatelessWidget {
  const PresetSplits({
    super.key,
    required this.onSelect,
    required this.currentSplit,
  });

  final void Function(List<SplitDay>) onSelect;
  final List<SplitDay> currentSplit;

  @override
  Widget build(BuildContext context) {
    final String? selectedPreset = currentSplit.isNotEmpty
        ? currentSplit.first.selectedPreset
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final cfg in PresetSplitConfig.presetConfigs)
          GradientButton(
            gradientVariant: cfg.gradient,
            isActive: selectedPreset == cfg.key,
            onPressed: () => onSelect(SplitDay.presetSplits[cfg.key]!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      cfg.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      cfg.nrOfDays,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
                Text(
                  cfg.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.accentLightGray,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
