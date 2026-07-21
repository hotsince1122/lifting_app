import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/app_bars/workout_session/workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/core/solid_button.dart';
import 'package:lifting_tracker_app/widgets/core/solid_card.dart';

class WorkoutSessionAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const WorkoutSessionAppBar(this.workoutSessionId, this.flow, {super.key});

  final int workoutSessionId;
  final WorkoutEditorFlow flow;

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final dayLabel = now.day.toString();
    final monthLabel = DateFormat('MMM', 'en_US').format(now);
    final double buttonHeight = 46;
    final double iconSize = 26;

    final actions = flow.getMenuActions(context, ref, workoutSessionId);

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
            onPressed: () async {
              await flow.onPrimaryAction(context, ref, workoutSessionId);
            },
            buttonHeight: buttonHeight,
            buttonWidth: 92,
            padding: EdgeInsets.zero,
            child: Text(
              flow.primaryButtonLabel,
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
                    constraints: const BoxConstraints.tightFor(width: 220),
                    menuPadding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_horiz,
                      fontWeight: FontWeight.bold,
                      size: iconSize + 4,
                      color: AppColors.onSurface,
                    ),
                    itemBuilder: (context) => [
                      for (int i = 0; i < actions.length; i++) ...[
                        PopupMenuItem(
                          padding: EdgeInsets.zero,
                          height: 62,
                          onTap: () => actions[i].onPressed(
                            context,
                            ref,
                            workoutSessionId,
                          ),
                          child: SizedBox(
                            width: 220,
                            height: 56,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(actions[i].icon),
                                const SizedBox(width: 8),
                                Text(
                                  actions[i].label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i != actions.length - 1)
                          PopupMenuItem(
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
                          ),
                      ],
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: AppColors.cardBorder, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    color: AppColors.card,
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
