import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/gradient_button.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/custom_split_selector.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/widgets/preset_splits.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_plan_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';

class SelectSplitPage extends ConsumerWidget {
  const SelectSplitPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitPlanAsync = ref.watch(activeSplitPlanProvider);

    return splitPlanAsync.when(
      skipLoadingOnReload: true,
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (activeSplitPlan) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              "Set up your workout week with:",
                              style: Theme.of(context).textTheme.titleSmall!
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        'Presets',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s12),

                      //Preset Splits Buttons
                      PresetSplits(currentSplit: activeSplitPlan),

                      const SizedBox(height: AppSpacing.s8),

                      //Divider Custom
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: const Divider(
                                color: AppColors.cardBorder,
                                thickness: 1.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.s12),
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

                      const SizedBox(height: AppSpacing.s8),

                      //Custom Split button
                      GradientButton(
                        gradientVariant: AppGradients.card,
                        isActive:
                            (activeSplitPlan != null &&
                            !activeSplitPlan.isPreset),
                        onPressed: () async {
                          await CustomSplitSelector.show(context);
                        },
                        buttonWidth: null,
                        buttonHeight: 46,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: AppSpacing.s4),
                            Text(
                              'Create Custom Split',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Pick how many days it has, then name each one.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
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
                    Text(
                      'Continue',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
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
