import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/gradient_variants.dart';
import 'package:lifting_tracker_app/providers/split_plan.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class PickExercisesPage extends ConsumerWidget {
  const PickExercisesPage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final splitPlanAsync = ref.watch(splitPlanProvider);

    return splitPlanAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (splitPlan) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                gradientVariant: Gradients.of(GradientVariant.darkTwo),
                child: Column(
                  children: [
                    Text(
                      "Select your exercises:",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add exercises for each wokout day.",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.accentLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SingleChildScrollView(
                child: Column(
                  children: [
                    for (final workoutDay in splitPlan) ...[
                      GradientCard(
                        padding: EdgeInsets.all(0),
                        gradientVariant: Gradients.of(GradientVariant.darkTwo),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Text(
                                workoutDay.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Text(
                                '0 selected',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.accentLightGray),
                              ),
                            ],
                          ),

                          subtitle: Text(
                            "Muscle groups: Not set yet",
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: AppColors.accentLightGray),
                          ),

                          controlAffinity: ListTileControlAffinity.leading,

                          iconColor: AppColors.accentLightGray,
                          backgroundColor: AppColors.bgSecondary,

                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),

                          
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
