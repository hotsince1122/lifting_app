import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_plan_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_day_summary_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/features/plans/presentation/pages/edit_day_page.dart';
import 'package:lifting_tracker_app/features/plans/presentation/pages/edit_split_page.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
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
                SizedBox(height: AppSpacing.s8),
                _SplitPlanSummary(),
                SizedBox(height: AppSpacing.s8),
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
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s4,
        horizontal: AppSpacing.s8,
      ),
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
        final exerciseCount = activeSplitPlanData.exerciseCount;

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
            const SizedBox(height: AppSpacing.s4),
            Text(
              '$cycleLengthInDays-day cycle · $exerciseCount exercise${exerciseCount > 1 ? 's' : ''}',
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
    final activeSplitDaysAsync = ref.watch(activeSplitDaysProvider);
    final activeSplitIdAsync = ref.watch(activeSplitIdProvider);

    return activeSplitDaysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('An error has occurred!')),
      data: (activeSplitDaysData) {
        if (activeSplitDaysData.isEmpty) {
          return const Center(child: Text('No split days found.'));
        }
        return activeSplitIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('An error has occurred!')),
          data: (activeSplitIdData) {
            if (activeSplitIdData == null) {
              return const Center(child: Text('An error has occurred!'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < activeSplitDaysData.length; i++) ...[
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditDayPage(
                          activeSplitDaysData[i].id,
                          activeSplitIdData,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: _SplitDayOverview(activeSplitDaysData[i]),
                  ),
                  if (i != activeSplitDaysData.length - 1)
                    Divider(
                      color: AppColors.cardBorder,
                      endIndent: AppSpacing.s4,
                      indent: AppSpacing.s4,
                      height: 1,
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SplitDayOverview extends ConsumerWidget {
  const _SplitDayOverview(this.splitDay);

  final SplitDay splitDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(splitDaySummaryProvider(splitDay.id));

    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Text('An error has occurred!')),
      ),
      data: (summary) {
        var muscleGroups = summary.muscleGroups.join(' / ');
        if (muscleGroups.isNotEmpty && !muscleGroups.contains(' ')) {
          muscleGroups += ' focused';
        }
        if (muscleGroups.isEmpty) {
          muscleGroups = 'no muscle groups';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      splitDay.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$muscleGroups · '
                      '${summary.exerciseCount} exercise${summary.exerciseCount != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: AppColors.primary,
                      ),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => EditSplitPage(planId)),
            );
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
