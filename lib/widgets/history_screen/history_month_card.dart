import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/view_model/history_month_vm.dart';
import 'package:lifting_tracker_app/providers/presentation/history_editing_mode.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/widgets/history_screen/history_workout_layout.dart';

class HistoryMonthCard extends ConsumerWidget {
  const HistoryMonthCard(this.historyMonthData, {super.key});

  final HistoryMonthVm historyMonthData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditingMode = ref.watch(historyEditModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                historyMonthData.label,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Text(
                '${historyMonthData.workoutCount} Workout${historyMonthData.workoutCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GradientCard(
          gradientVariant: AppGradients.card,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (int i = 0; i < historyMonthData.workouts.length; i++) ...[
                HistoryWorkoutLayout(
                  key: ValueKey(historyMonthData.workouts[i].workoutId),
                  historyMonthData.workouts[i],
                  isEditingMode,
                  _positionFor(i, historyMonthData.workouts.length),
                ),
                if (i != historyMonthData.workouts.length - 1)
                  SizedBox(
                    height: 0,
                    child: Divider(color: AppColors.cardBorder, thickness: 1),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

enum WorkoutPositionInLayout { first, between, last, only }

WorkoutPositionInLayout _positionFor(int index, int length) {
  if (index == 0) {
    if (length == 1) {
      return WorkoutPositionInLayout.only;
    } else {
      return WorkoutPositionInLayout.first;
    }
  }

  if (index == length - 1) {
    return WorkoutPositionInLayout.last;
  }

  return WorkoutPositionInLayout.between;
}
