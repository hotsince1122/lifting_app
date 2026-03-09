import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/can_user_finish_setup.dart';
import 'package:lifting_tracker_app/providers/exercises_in_a_day.dart';
import 'package:lifting_tracker_app/providers/split_day_summary_tile.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class AddedExercises extends ConsumerWidget {
  const AddedExercises(this.dayId, {super.key});

  final String dayId;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesInADayAsync = ref.watch(exercisesInADayProvider(dayId));

    return exercisesInADayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('An error has occured! Try again.'),
      data: (exercisesInADay) {
        if (exercisesInADay.isEmpty) return const SizedBox();

        return DragBoundary(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: exercisesInADay.length,
            onReorder: (oldIndex, newIndex) async {
              await ref
                  .read(exercisesInADayProvider(dayId).notifier)
                  .reorderExercises(oldIndex, newIndex);
              await ref
                      .read(splitDaySummaryProvider(dayId).notifier)
                      .refresh();
            },
            dragBoundaryProvider: (context) => DragBoundary.forRectOf(context),
            buildDefaultDragHandles: false,
            itemBuilder: (context, i) {
              final exercise = exercisesInADay[i];

              final label = exercise.name[0] + exercise.name.substring(1);

              return Dismissible(
                key: ValueKey(exercise.idInDayExerciseRelation),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await ref
                      .read(exercisesInADayProvider(dayId).notifier)
                      .deleteExerciseFromDay(exercise.idInDayExerciseRelation!);

                  await ref
                      .read(splitDaySummaryProvider(dayId).notifier)
                      .refresh();

                  await ref.read(canUserFinishSetupProvider.notifier).refresh();
                },
                background: Container(
                  alignment: const Alignment(0.95, 0),
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.delete_outline_outlined),
                ),
                child: Column(
                  children: [
                    Divider(
                      height: 0.5,
                      color: AppColors.accentLightGray,
                      indent: 16,
                      endIndent: 16,
                    ),
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      minVerticalPadding: 0,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: ReorderableDelayedDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                    Divider(
                      height: 0.5,
                      color: AppColors.accentLightGray,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
