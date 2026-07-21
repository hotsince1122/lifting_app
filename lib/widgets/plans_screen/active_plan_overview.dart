import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/active_split_days_options.dart';
import 'package:lifting_tracker_app/screens/plans/edit_day.dart';
import 'package:lifting_tracker_app/screens/plans/edit_split.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/core/gradient_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivePlanOverview extends StatelessWidget {
  const ActivePlanOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradientVariant: AppGradients.softCard,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _ActivePill(),
                SizedBox(height: 12),
                _SplitPlanSummary(),
                SizedBox(height: 16),
                _SplitDays(),
              ],
            ),
            Positioned(top: 0, right: 0, child: _EditSplitButton()),
          ],
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryTransparent,
        border: BoxBorder.all(color: AppColors.primary, width: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        'ACTIVE',
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SplitPlanSummary extends ConsumerWidget {
  const _SplitPlanSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitPlanAsync = ref.watch(activeSplitPlanProvider);

    return activeSplitPlanAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (activeSplitPlanData) {
        if (activeSplitPlanData == null) {
          return Center(child: Text('No active plan found.'));
        }

        final cycleLengthInDays = activeSplitPlanData.cycleLengthInDays;
        final nrOfExercises = activeSplitPlanData.nrOfExercises;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              activeSplitPlanData.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '$cycleLengthInDays-day cycle · $nrOfExercises exercise${nrOfExercises > 1 ? 's' : ''}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
            ),
          ],
        );
      },
    );
  }
}

class _SplitDays extends ConsumerWidget {
  const _SplitDays();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitDaysAsync = ref.watch(activeSplitDaysOptionsProvider);

    return activeSplitDaysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('An error has occurred!')),
      data: (activeSplitDaysData) {
        if (activeSplitDaysData.isEmpty) {
          return const Center(child: Text('No split days found.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < activeSplitDaysData.length; i++) ...[
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        EditDay(activeSplitDaysData[i].dayId!),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeSplitDaysData[i].workoutName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${activeSplitDaysData[i].muscleGroups} · '
                              '${activeSplitDaysData[i].nrOfExercises} exercise${activeSplitDaysData[i].nrOfExercises != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (i != activeSplitDaysData.length - 1)
                Divider(
                  color: AppColors.cardBorder,
                  endIndent: 4,
                  indent: 4,
                  height: 1,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _EditSplitButton extends ConsumerWidget {
  const _EditSplitButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlanIdAsync = ref.watch(
      activeSplitPlanProvider.select(
        (state) => state.whenData((plan) => plan?.id),
      ),
    );

    return activePlanIdAsync.when(
      loading: () => const SizedBox(
        width: 96,
        height: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (planId) {
        if (planId == null) {
          return const SizedBox.shrink();
        }

        return TextButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => EditSplit(planId)));
          },
          style: TextButton.styleFrom(
            side: BorderSide(color: AppColors.cardBorder),
            backgroundColor: AppColors.secondary.withAlpha(18),
            visualDensity: VisualDensity.compact,
          ),
          icon: Icon(
            PhosphorIcons.pencil(),
            size: 14,
            color: AppColors.secondary,
          ),
          label: Text(
            'Edit split',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        );
      },
    );
  }
}
