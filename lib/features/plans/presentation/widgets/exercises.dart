import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/planned_exercises_list_view.dart';

class Exercises extends StatelessWidget {
  const Exercises(this.dayId, {super.key});

  final String dayId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(dayId),
          const SizedBox(height: AppSpacing.s16),
          GradientCard(
            gradientVariant: AppGradients.card,
            padding: EdgeInsets.zero,
            child: PlannedExercisesListView(
              dayId,
              includeBottomDivider: false,
              isTileDense: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header(this.dayId);

  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedExercisesAsync = ref.watch(plannedExercisesProvider(dayId));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Exercises',
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),

        plannedExercisesAsync.when(
          loading: () => Text(
            '  exercise ',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0,
            ),
          ),
          error: (error, stackTrace) =>
              const Center(child: Text('Could not load exercise count.')),
          data: (plannedExercises) {
            final exerciseCount = plannedExercises.length;
            final String label = exerciseCount == 0
                ? 'Day has no exercises planned'
                : '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}';

            return Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0,
              ),
            );
          },
        ),
      ],
    );
  }
}
