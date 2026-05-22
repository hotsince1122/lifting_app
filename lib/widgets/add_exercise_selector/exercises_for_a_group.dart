import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/all_exercises_from_a_muscle_group.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class ExercisesForGroupPage extends ConsumerWidget {
  const ExercisesForGroupPage(
    this.muscleGroup, {
    required this.onEditExercise,
    super.key,
  });

  final String muscleGroup;
  final void Function(Exercise exercise) onEditExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesFromAMuscleGroup(muscleGroup));

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('An error occured! Try again.'),
      data: (exercises) => Container(
        height: double.infinity,
        width: double.infinity,
        color: AppColors.card.withAlpha(253),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: exercises.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.cardGradient),
            itemBuilder: (context, i) {
              final exercise = exercises[i];

              final label =
                  exercise.name[0].toUpperCase() + exercise.name.substring(1);

              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                minVerticalPadding: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                trailing: IconButton(
                  onPressed: () {
                    onEditExercise(exercise);
                  },
                  icon: Icon(Icons.more_horiz, size: 22),
                ),
                title: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () =>
                    Navigator.of(context, rootNavigator: true).pop(exercise),
              );
            },
          ),
        ),
      ),
    );
  }
}
