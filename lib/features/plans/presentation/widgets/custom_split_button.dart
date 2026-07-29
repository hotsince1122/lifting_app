import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/custom_split_selector.dart';

class CustomSplitButton extends StatelessWidget {
  const CustomSplitButton({super.key});

  @override
  Widget build(BuildContext context) {
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
            await CustomSplitSelector.show(context);
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
