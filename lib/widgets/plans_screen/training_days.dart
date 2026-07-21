import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/split_day_summary_tile.dart';
import 'package:lifting_tracker_app/screens/plans/edit_day.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/core/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/delete_flow.dart/delete_day_flow.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/delete_validation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TrainingDays extends StatelessWidget {
  const TrainingDays(this.splitId, {super.key});

  final int splitId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(splitId),
          const SizedBox(height: 16),
          _Body(splitId),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header(this.splitId);

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nrOfDaysCycleAsync = ref.watch(splitPlanProvider(splitId));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Training days',
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),

        nrOfDaysCycleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Center(
            child: Text('Could not load nr of split day cycle.'),
          ),
          data: (nrOfDaysCycleData) {
            if (nrOfDaysCycleData == null) {
              return Text(
                'Split has no days',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0,
                ),
              );
            }

            final nrOfDaysCycle = nrOfDaysCycleData.cycleLengthInDays;

            return Text(
              '$nrOfDaysCycle-day cycle',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body(this.splitId);

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitDayAsync = ref.watch(splitDaysProvider(splitId));

    return splitDayAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Center(child: Text('Could not load split days')),
      data: (splitDay) {
        return splitDay.isEmpty
            ? SizedBox.shrink()
            : GradientCard(
                gradientVariant: AppGradients.card,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: double.infinity,
                  child: DragBoundary(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: splitDay.length,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) async {
                        final splitDayId = splitDay[oldIndex].id;

                        await ref
                            .read(splitDaysProvider(splitId).notifier)
                            .reorderSplitDays(oldIndex, newIndex, splitDayId);
                      },
                      dragBoundaryProvider: (context) =>
                          DragBoundary.forRectOf(context),
                      itemBuilder: (context, i) {
                        final dayId = splitDay[i].id;
                        final dayName = splitDay[i].name;

                        final splitDayInfoAsync = ref.watch(
                          splitDaySummaryProvider(dayId),
                        );

                        return Column(
                          key: ValueKey(dayId),
                          children: [
                            InkWell(
                              highlightColor: Colors.transparent,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditDay(dayId),
                                  ),
                                );
                              },
                              child: ListTile(
                                title: Text(
                                  dayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                subtitle: splitDayInfoAsync.when(
                                  loading: () => Container(
                                    width: 32,
                                    height: 16,
                                    color: AppColors.secondary.withAlpha(18),
                                  ),
                                  error: (_, _) => const Center(
                                    child: Text(
                                      'Could not load nr of exercises.',
                                    ),
                                  ),
                                  data: (splitDayInfo) {
                                    final int nrOfExercises =
                                        splitDayInfo.exerciseCount;
                                    return Text(
                                      '$nrOfExercises exercise${nrOfExercises == 1 ? '' : 's'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: AppColors.primary,
                                            letterSpacing: 0,
                                          ),
                                    );
                                  },
                                ),
                                leading: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 22,
                                  color: AppColors.onSurfaceMuted,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.onSurfaceMuted,
                                    ),
                                    const SizedBox(width: 18),
                                    PopupMenuButton(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 180,
                                          ),
                                      splashRadius: 16,
                                      menuPadding: const EdgeInsets.symmetric(
                                        vertical: 0,
                                        horizontal: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      position: PopupMenuPosition.under,
                                      offset: Offset(0, 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: AppColors.cardBorder,
                                          width: 1,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      color: AppColors.card,
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Icon(
                                          Icons.more_horiz,
                                          size: 22,
                                          color: AppColors.onSurfaceMuted,
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          onTap: () async {
                                            await showDeleteValidation(
                                              context,
                                              DeleteDayFlow(
                                                splitId: splitId,
                                                dayId: dayId,
                                                ref: ref,
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                PhosphorIcons.trash(),
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Delete Day',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            i != (splitDay.length - 1)
                                ? Divider(
                                    thickness: 1,
                                    height: 1,
                                    color: AppColors.cardBorder,
                                    indent: 16,
                                    endIndent: 16,
                                  )
                                : const SizedBox.shrink(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
      },
    );
  }
}
