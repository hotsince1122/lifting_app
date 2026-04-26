import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/custom_split.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/preset_splits.dart';

import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/custom_split_selector.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';

class SelectSplitPage extends ConsumerWidget {
  const SelectSplitPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<CustomSplit?> openCustomSplitSelector(
      BuildContext context,
      double screenWidth,
    ) {
      return showModalBottomSheet<CustomSplit>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black12,
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
          padding: const EdgeInsets.fromLTRB(18, 32, 18, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: AppGradients.card,
                child: Column(
                  children: [
                    Text(
                      "Choose your training split",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12,),
                    Text(
                      "Set up your workout week with:",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.primary,
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
                        color: AppColors.cardBorder,
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
                        color: AppColors.cardBorder,
                        thickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              //Custom Split button
              GradientButton(
                gradientVariant: AppGradients.card,
                isActive:
                    (activeSplitPlan != null &&
                    !activeSplitPlan.isPreset),
                onPressed: () async {
                  final CustomSplit? customSplit =
                      await openCustomSplitSelector(context, screenWidth);
                  if (customSplit != null) {
                    ref.read(activeSplitPlanProvider.notifier).addAndChangeToCustom(customSplit);
                  }
                },
                buttonWidth: screenWidth - 172,
                buttonHeight: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.primary,
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
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              SolidButton(
                isActive: activeSplitPlan == null,
                buttonHeight: 54,
                onPressed: activeSplitPlan == null
                    ? () {}
                    : () => controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.background)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.background,),
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