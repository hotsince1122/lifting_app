import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plans_ids_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/pages/edit_split_page.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/delete/delete_flow/delete_split_flow.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/delete_validation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class YourPlans extends ConsumerWidget {
  const YourPlans({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitPlansIdsAsync = ref.watch(splitPlansIdsProvider);
    final activeSplitIdAsync = ref.watch(activeSplitIdProvider);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your plans',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 12),

          splitPlansIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                const Center(child: Text('Could not load plans.')),
            data: (splitPlanIds) {
              if (splitPlanIds.isEmpty) {
                return const Text('You have no plans yet.');
              }

              return activeSplitIdAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Text('Could not load split id.')),
                data: (activeSplitId) {
                  return Column(
                    children: [
                      for (final splitPlanId in splitPlanIds)
                        if (splitPlanId != activeSplitId)
                          _SplitPlanCard(splitPlanId: splitPlanId),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SplitPlanCard extends ConsumerWidget {
  const _SplitPlanCard({required this.splitPlanId});

  final int splitPlanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitPlanAsync = ref.watch(splitPlanProvider(splitPlanId));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: splitPlanAsync.when(
        loading: () => const GradientCard(
          gradientVariant: AppGradients.card,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => const GradientCard(
          gradientVariant: AppGradients.card,
          child: Text('Could not load this plan.'),
        ),
        data: (splitPlan) {
          if (splitPlan == null) {
            return const SizedBox.shrink();
          }

          final name = splitPlan.name;
          final cycleLengthInDays = splitPlan.cycleLengthInDays;
          final exerciseCount = splitPlan.exerciseCount;

          return Stack(
            children: [
              GradientCard(
                gradientVariant: AppGradients.card,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '$cycleLengthInDays-day cycle · $exerciseCount exercise${exerciseCount != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton(
                  menuPadding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: AppColors.cardBorder, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: AppColors.card,
                  icon: const Icon(Icons.more_horiz, size: 16),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    maximumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.secondary.withAlpha(18),
                    side: BorderSide(color: AppColors.cardBorder),
                    shape: const CircleBorder(),
                  ),
                  offset: Offset(0, 7),

                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () async {
                        try {
                          await ref
                              .read(activeSplitIdProvider.notifier)
                              .changeToExisting(splitPlanId);
                        } catch (_) {
                          if (!context.mounted) return;
                          SnackBarError.show(
                            context,
                            'Could not activate split. Try again!',
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Set as active',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditSplitPage(splitPlanId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.pencil(), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () async {
                        await showDeleteValidation(
                          context,
                          DeleteSplitFlow(splitPlanId: splitPlanId, ref: ref),
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
                            'Delete',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
