import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/buttons/gradient_button.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_launch/quick_workout_launch_strategy.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_launch/session_launch_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuickWorkout extends ConsumerWidget {
  const QuickWorkout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SessionLaunchButton(
      launchFlow: const QuickWorkoutLaunchStrategy(),
      buttonBuilder: (context, onPressed, isSessionAlreadyActive, child) {
        return isSessionAlreadyActive
            ? const SizedBox()
            : GradientButton(
                isActive: false,
                onPressed: onPressed,
                gradientVariant: AppGradients.card,
                buttonHeight: 64,
                padding: EdgeInsets.all(8),
                child: child,
              );
      },
      contentBuilder: (context, isActive, workoutName) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.lightning(), size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Quick', style: Theme.of(context).textTheme.titleMedium),
          ],
        );
      },
    );
  }
}
