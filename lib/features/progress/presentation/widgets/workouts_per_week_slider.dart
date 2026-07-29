import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';

class WorkoutsPerWeekSlider extends ConsumerStatefulWidget {
  const WorkoutsPerWeekSlider({super.key});

  @override
  ConsumerState<WorkoutsPerWeekSlider> createState() =>
      _WorkoutsPerWeekSliderState();
}

class _WorkoutsPerWeekSliderState extends ConsumerState<WorkoutsPerWeekSlider> {
  int? _selectedTarget;
  bool _isSaving = false;

  Future<void> _saveTarget(int target) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(weeklyWorkoutProgressProvider.notifier)
          .saveNewTarget(target);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedTarget = null;
        _isSaving = false;
      });

      SnackBarError.show(
        context,
        'Could not save the weekly target. Please try again.',
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedTarget = null;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutsPerWeekAsync = ref.watch(weeklyWorkoutProgressProvider);

    return workoutsPerWeekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (weeklyWorkoutProgress) {
        final target = _selectedTarget ?? weeklyWorkoutProgress.target;

        return Slider(
          value: target.toDouble(),
          max: 7,
          min: 1,
          divisions: 6,
          activeColor: AppColors.onSurface,
          inactiveColor: AppColors.surface,
          label: '$target day${target > 1 ? 's' : ''}',
          thumbColor: AppColors.primary,
          onChanged: _isSaving
              ? null
              : (value) {
                  setState(() {
                    _selectedTarget = value.round();
                  });
                },
          onChangeEnd: _isSaving
              ? null
              : (value) async {
                  await _saveTarget(value.round());
                },
        );
      },
    );
  }
}
