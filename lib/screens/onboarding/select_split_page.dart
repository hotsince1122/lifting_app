import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/preset_splits.dart';

import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/custom_split_selector.dart';
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
    final splitPlanAsync = ref.watch(activeSplitPlanProvider);

    return splitPlanAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (activeSplitPlan) {

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: Gradients.of(AppGradients.darkThree),
                child: Column(
                  children: [
                    Text(
                      "Choose your training split",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8,),
                    Text(
                      "Set up your workout week with:",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Presets',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              //Preset Splits Buttons
              PresetSplits(currentSplit: activeSplitPlan),

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
                    (activeSplitPlan != null &&
                    !activeSplitPlan.isPreset),
                onPressed: () async {
                  final List<SplitDay>? customSplit =
                      await openCustomSplitSelector(context, screenWidth);
                  if (customSplit != null) {
                    ref.read(activeSplitPlanProvider.notifier).addAndChangeToCustom(customSplit);
                  }
                },
                gradientVariant: Gradients.of(AppGradients.darkOne),
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
              const SizedBox(height: 8),
              Text(
                'Pick how many days it has, then name each one.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue.withAlpha(180),
                ),
              ),
              const Spacer(),
              GradientButton(
                isActive: activeSplitPlan == null,
                buttonHight: 48,
                onPressed: activeSplitPlan == null
                    ? () {}
                    : () => controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      ),
                gradientVariant: Gradients.of(AppGradients.lightOne),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue', style: Theme.of(context).textTheme.titleLarge),
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