import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/workout_launch/session_launch_button.dart';
import 'package:lifting_tracker_app/widgets/core/solid_button.dart';
import 'package:lifting_tracker_app/widgets/workout_launch/split_workout_launch_flow.dart';

class StartSession extends ConsumerWidget {
  const StartSession({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SessionLaunchButton(
      launchFlow: const SplitWorkoutLaunchFlow(),
      buttonBuilder: (context, onPressed, isSessionAlreadyActive, child) {
        return SolidButton(
          isActive: false,
          onPressed: onPressed,
          buttonHeight: 62,
          child: child,
        );
      },
      contentBuilder: (context, isActive, workoutName) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 30, color: AppColors.background),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Resume ' : 'Start ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(color: AppColors.background),
            ),
            Text(
              workoutName,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
      },
    );
  }
}
