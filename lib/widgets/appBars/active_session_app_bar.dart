import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/reorder_exercises_sheet.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';
import 'package:lifting_tracker_app/widgets/solid_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActiveSessionAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const ActiveSessionAppBar(this.activeSessionId, {super.key});

  final int activeSessionId;

  Future<void> _handleFinish(
    BuildContext context,
    WidgetRef ref,
    int activeSessionId,
  ) async {
    final sessionStatusNotifier = ref.read(
      currentSessionStatusProvider.notifier,
    );

    final hasEmptySet = await sessionStatusNotifier.checkIfAnySetEmpty(
      activeSessionId,
    );

    final userModifiedPlannedExercises = await sessionStatusNotifier
        .checkIfUserModifiedExercisesPlanned(activeSessionId);

    if (hasEmptySet && context.mounted) {
      await _handleEmptySets(context, sessionStatusNotifier);
    }

    if (userModifiedPlannedExercises && context.mounted) {
      await _handleUpdatePlan(context, sessionStatusNotifier);
    }

    await sessionStatusNotifier.endSession(activeSessionId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleEmptySets(
    BuildContext context,
    CurrentSessionStatusNotifier sessionStatusNotifier,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Weight or reps missing'),
          content: const Text(
            'Do you want to autofill them using last time weight and reps?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Yes, Autofill'),
              onPressed: () async {
                await sessionStatusNotifier.saveEmptySetsWithHints(
                  activeSessionId,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('No Thanks'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpdatePlan(
    BuildContext context,
    CurrentSessionStatusNotifier sessionStatusNotifier,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Update plan?'),
          content: const Text(
            'You changed the exercises in this session. Save this order and exercise list for future sessions?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Update plan'),
              onPressed: () async {
                await sessionStatusNotifier.updateCurrentPlan(activeSessionId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('This session only'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final dayLabel = now.day.toString();
    final monthLabel = DateFormat('MMM', 'en_US').format(now);
    final double buttonHeight = 46;
    final double iconSize = 26;

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SolidButton(
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.card,
            buttonHeight: buttonHeight,
            buttonWidth: 58,
            padding: EdgeInsets.zero,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: iconSize,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),

          SolidButton(
            onPressed: () {
              _handleFinish(context, ref, activeSessionId);
            },
            buttonHeight: buttonHeight,
            buttonWidth: 92,
            padding: EdgeInsets.zero,
            child: Text(
              'Finish',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Text(
            '$dayLabel $monthLabel',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          SolidCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: buttonHeight,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.timer_sharp,
                      size: iconSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton(
                    icon: PhosphorIcon(
                      PhosphorIcons.dotsThreeOutline(PhosphorIconsStyle.bold),
                      size: iconSize,
                      color: AppColors.onSurface,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => ReorderExercisesSheet.openSheet(
                          context,
                          screenWidth,
                          activeSessionId,
                        ),
                        child: SizedBox(
                          width: 145,
                          height: 60,
                          child: Center(
                            child: Text(
                              'Reorder Exercises',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: AppColors.cardBorder, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    color: AppColors.card.withAlpha(245),
                    menuPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
