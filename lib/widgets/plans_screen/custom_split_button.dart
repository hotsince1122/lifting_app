import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/custom_split.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/custom_split_selector.dart';

class CustomSplitButton extends ConsumerWidget {
  const CustomSplitButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: Radius.circular(20),
          color: AppColors.primaryTransparent,
          borderPadding: EdgeInsets.zero,
          dashPattern: const [4, 2],
        ),
        child: InkWell(
          onTap: () async {
            final CustomSplit? customSplit = await CustomSplitSelector.show(
              context,
            );
            if (customSplit != null) {
              ref
                  .read(activeSplitPlanProvider.notifier)
                  .addAndChangeToCustom(customSplit);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Create custom split',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
