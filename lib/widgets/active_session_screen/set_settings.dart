import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SetSettings extends ConsumerStatefulWidget {
  const SetSettings(
    this.screenWidth,
    this.activeSessionSetId,
    this.isWarmup,
    this.activeSessionId, {
    required this.onDelete,
    super.key,
  });

  final double screenWidth;
  final int activeSessionSetId;
  final int activeSessionId;
  final bool isWarmup;
  final Future<void> Function() onDelete;

  static Future<void> openSetSettings(
    BuildContext context,
    double screenWidth,
    int activeSessionSetId,
    bool isWarmup,
    int activeSessionId,
    Future<void> Function() onDelete,
  ) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => SetSettings(
        screenWidth,
        activeSessionSetId,
        isWarmup,
        activeSessionId,
        onDelete: onDelete,
      ),
    );
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SetSettingsState();
}

class SetSettingsState extends ConsumerState<SetSettings> {
  Widget markIfSelected(bool isSelected, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          Navigator.of(context).maybePop();
          if (!isSelected) {
            await ref
                .read(exercisesAndSetsProvider(widget.activeSessionId).notifier)
                .toggleSetWarmup(widget.activeSessionSetId);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardSoftEnd : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.cardBorder : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWarmup = widget.isWarmup;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.40,
            width: widget.screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.card.withAlpha(253),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                      iconSize: 18,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Set type',
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          markIfSelected(!isWarmup, 'Normal'),
                          markIfSelected(isWarmup, 'Warm up'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: () async {
                        final onDelete = widget.onDelete;
                        await Navigator.of(context).maybePop();
                        await onDelete();
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            Colors.red.withValues(alpha: 0.12),
                            AppColors.surface,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Delete',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(color: Colors.red),
                            ),
                            const Spacer(),
                            PhosphorIcon(
                              PhosphorIcons.trash(PhosphorIconsStyle.regular),
                              color: Colors.red,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
