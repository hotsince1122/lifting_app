import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class AddDayToSplit extends ConsumerWidget {
  const AddDayToSplit(this.splitId, {super.key});

  final int splitId;

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
            await ref.read(splitDaysProvider(splitId).notifier).createNewDay();
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
                  'Add day',
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
