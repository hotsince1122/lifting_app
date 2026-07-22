import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

class WorkoutsPerWeekSlider extends ConsumerWidget {
  const WorkoutsPerWeekSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsPerWeekAsync = ref.watch(weeklyWorkoutProgressProvider);

    return workoutsPerWeekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (weeklyWorkoutProgress) {
        final target = weeklyWorkoutProgress.target;

        return Slider(
          value: target.toDouble(),
          max: 7,
          min: 1,
          divisions: 6,
          activeColor: AppColors.onSurface,
          inactiveColor: AppColors.surface,
          label: '$target day${target > 1 ? 's' : ''}',
          thumbColor: AppColors.primary,

          onChanged: (value) {
            ref
                .read(weeklyWorkoutProgressProvider.notifier)
                .saveNewTarget(value.toInt());
          },
        );
      },
    );
  }
}
