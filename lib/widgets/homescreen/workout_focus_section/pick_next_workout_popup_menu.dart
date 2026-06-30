import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/active_split_days_vm.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class PickNextWorkoutPopupMenu extends ConsumerWidget {
  const PickNextWorkoutPopupMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitDaysVmAsync = ref.watch(activeSplitDaysVmProvider);

    final menuDivider = PopupMenuItem(
      enabled: false,
      padding: EdgeInsets.zero,
      height: 1,
      child: Divider(
        height: 1,
        thickness: 1,
        indent: 10,
        endIndent: 10,
        color: AppColors.cardBorder,
      ),
    );

    return activeSplitDaysVmAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (activeSplitDaysVm) {
        return SizedBox(
          width: 32,
          height: 32,
          child: PopupMenuButton(
            constraints: const BoxConstraints.tightFor(width: 240),
            menuPadding: EdgeInsets.symmetric(vertical: 6),
            splashRadius: 16,
            borderRadius: BorderRadius.circular(16),
            position: PopupMenuPosition.under,
            offset: Offset(0, 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            color: AppColors.card,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: BoxBorder.all(color: AppColors.cardBorder, width: 1.5),
                color: AppColors.onCardTransparent,
              ),
              child: Icon(
                Icons.navigate_next_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                padding: EdgeInsets.symmetric(horizontal: 12),
                enabled: false,
                height: 38,
                child: Text(
                  'Pick next session',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              menuDivider,
              for (final splitDay in activeSplitDaysVm) ...[
                PopupMenuItem(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  height: 38,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          splitDay.workoutName,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          splitDay.muscleGroups ??
                              'no muscle groups selected',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.primary,
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
