import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/simple_app_bar.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/core/utils/to_upper_first.dart';
import 'package:lifting_tracker_app/features/exercises/application/exercises_by_muscle_group_controller.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/progress/application/exercise_has_history_provider.dart';
import 'package:lifting_tracker_app/features/progress/presentation/pages/exercise_chart_page.dart';

class ExercisesPage extends ConsumerWidget {
  const ExercisesPage(this.muscleGroup, {super.key});

  final String muscleGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = toUpperFirst(muscleGroup);
    final exercisesAsync = ref.watch(
      exerciseByMuscleGroupProvider(muscleGroup),
    );

    return Scaffold(
      appBar: SimpleAppBar(title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              bottom: AppSpacing.s32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXERCISES',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: AppSpacing.s12),
                  exercisesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(
                      child: Text(
                        "An error has occurred!\nCannot load exercises!",
                      ),
                    ),
                    data: (exercises) {
                      return GradientCard(
                        gradientVariant: AppGradients.deepCard,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final exercise in exercises) ...[
                              ExerciseTile(exercise),
                              if (exercise != exercises[exercises.length - 1])
                                SizedBox(
                                  height: 1,
                                  child: const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.cardGradient,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseTile extends ConsumerWidget {
  const ExerciseTile(this.exercise, {super.key});

  final CatalogExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHistoryAsync = ref.watch(exerciseHasHistoryProvider(exercise.id));

    final (subtitle, trailing, onTap) = hasHistoryAsync.when(
      loading: () => (null, null, null),
      error: (_, _) => (null, null, null),
      data: (hasHistory) => (
        hasHistory
            ? null
            : Text(
                'No history yet',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
              ),
        hasHistory
            ? Icon(Icons.chevron_right_outlined, color: AppColors.primary)
            : null,
        hasHistory ? () => ExerciseChartPage.openPage(context, exercise) : null
      ),
    );

    return ListTile(
      minTileHeight: 70,
      title: Text(exercise.name, overflow: TextOverflow.ellipsis),
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
