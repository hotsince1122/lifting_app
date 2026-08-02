import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';

class AddToSplit extends ConsumerWidget {
  const AddToSplit({
    required this.buttonLabel,
    required this.addFunction,
    super.key,
  });

  final String buttonLabel;
  final Future<void> Function() addFunction;

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
            try {
              await addFunction();
            } catch (_) {
              if (!context.mounted) return;
              SnackBarError.show(context, 'Did not add. Try again!');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  buttonLabel,
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
