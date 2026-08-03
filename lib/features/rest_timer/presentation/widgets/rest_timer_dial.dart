import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/rest_timer/domain/rest_timer_state.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/view_data/rest_timer_duration_formatter.dart';

class RestTimerDial extends StatelessWidget {
  const RestTimerDial({
    required this.state,
    required this.displayedDuration,
    super.key,
  });

  final RestTimerState state;
  final Duration displayedDuration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: state.remainingFraction),
      duration: const Duration(milliseconds: 600),
      curve: Curves.linear,
      builder: (context, progress, child) {
        return SizedBox.square(
          dimension: MediaQuery.of(context).size.width * 0.54,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.surface,
                color: AppColors.secondary,
              ),
              Center(child: child),
            ],
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatRestTimerDuration(displayedDuration),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            state.isRunning ? 'Resting' : 'Ready',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
