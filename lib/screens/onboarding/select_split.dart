import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifting_tracker_app/models/gradient_variants.dart';
import 'package:lifting_tracker_app/models/split_days.dart';
import 'package:lifting_tracker_app/providers/split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class SelectSplitPage extends StatelessWidget {
  const SelectSplitPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientCard(
            gradientVariant: Gradients.of(GradientVariant.darkThree),
            child: Text(
              "Let's set up your traning split:",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
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
          PresetSplits(),

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
          Hero(
            tag: 'customSplit',
            child: Material(
              type: MaterialType.transparency,
              child: GradientButton(
                isActive: false,
                onPressed: () => () {} /* _openCustomSplitTab(context) */,
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
            onPressed: () => controller.nextPage(
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
  }
}

class PresetSplits extends ConsumerWidget {
  const PresetSplits({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitPlanAsync = ref.watch(splitPlanProvider);

    return splitPlanAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (splitPlan) {
        void onSelect(List<SplitDay> newSplit) {
          ref.read(splitPlanProvider.notifier).changeSplit(newSplit);
        }

        final String? selectedPreset = splitPlan.isNotEmpty
            ? splitPlan.first.selectedPreset
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
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.accentLightGray),
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
      },
    );
  }
}
