import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/providers/presentation/plans_change_weekly_target_mode.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TargetWeekButton extends ConsumerStatefulWidget {
  const TargetWeekButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      TargetWeekButtonState();
}

class TargetWeekButtonState extends ConsumerState<TargetWeekButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final targetAsync = ref.watch(weeklyWorkoutProgressProvider);

    return TextButton.icon(
      onPressed: () {
        setState(() {
          isPressed = !isPressed;
          ref.read(changeWeeklyTargetMode.notifier).toggle();
        });
      },
      icon: Icon(PhosphorIcons.target(), size: 16, color: AppColors.secondary),
      style: TextButton.styleFrom(
        side: BorderSide(
          color: isPressed
              ? AppColors.secondary.withAlpha(80)
              : AppColors.cardBorder,
        ),
        backgroundColor: AppColors.onCardTransparent,
      ),
      label: targetAsync.when(
        loading: () => Container(
          width: double.infinity,
          height: double.infinity,
          color: Color.fromARGB(255, 32, 40, 54),
        ),
        error: (_, _) => const Center(child: Text('Error')),
        data: (target) => Text(
          '${target.target.toString()}/wk',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
