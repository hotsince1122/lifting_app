import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/reorder_exercises_sheet.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';
import 'package:lifting_tracker_app/widgets/solid_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
                          workoutSessionId,
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
