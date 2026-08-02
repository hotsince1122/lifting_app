import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/history/presentation/state/history_workout_position.dart';
import 'package:lifting_tracker_app/features/history/presentation/view_data/history_month_view_data.dart';
import 'package:lifting_tracker_app/features/history/presentation/state/history_editing_mode_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/history/presentation/widgets/history_workout_tile.dart';

class HistoryMonthCard extends ConsumerWidget {
  const HistoryMonthCard(this.historyMonthData, {super.key});

  final HistoryMonthViewData historyMonthData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditingMode = ref.watch(historyEditModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              Text(
                historyMonthData.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: AppSpacing.s8),
        GradientCard(
          gradientVariant: AppGradients.card,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            children: [
              for (int i = 0; i < historyMonthData.workouts.length; i++) ...[
                HistoryWorkoutTile(
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
        const SizedBox(height: AppSpacing.s16),
      ],
    );
  }
}

HistoryWorkoutPosition _positionFor(int index, int length) {
  if (index == 0) {
    if (length == 1) {
      return HistoryWorkoutPosition.only;
    } else {
      return HistoryWorkoutPosition.first;
    }
  }

  if (index == length - 1) {
    return HistoryWorkoutPosition.last;
  }

  return HistoryWorkoutPosition.between;
}
