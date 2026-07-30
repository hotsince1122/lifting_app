import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';

class PlannedExercisesListView extends ConsumerWidget {
  const PlannedExercisesListView(
    this.dayId, {
    required this.includeBottomDivider,
    required this.isTileDense,
    super.key,
  });

  final String dayId;
  final bool includeBottomDivider;
  final bool isTileDense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedExercisesAsync = ref.watch(plannedExercisesProvider(dayId));

    return plannedExercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('An error has occured! Try again.'),
      data: (plannedExercises) {
        if (plannedExercises.isEmpty) return const SizedBox();

        return DragBoundary(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: plannedExercises.length,
            onReorder: (oldIndex, newIndex) async {
              try {
                await ref
                    .read(plannedExercisesProvider(dayId).notifier)
                    .reorderExercises(oldIndex, newIndex);
              } catch (_) {
                if (!context.mounted) return;
                SnackBarError.show(
                  context,
                  'Could not reorder exercises. Try again!',
                );
              }
            },
            dragBoundaryProvider: (context) => DragBoundary.forRectOf(context),
            buildDefaultDragHandles: false,
            itemBuilder: (context, i) {
              final plannedExercise = plannedExercises[i];
              final catalogExercise = plannedExercise.catalogExercise;

              final label =
                  catalogExercise.name[0] + catalogExercise.name.substring(1);

              return Dismissible(
                key: ValueKey(plannedExercise.relationId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  try {
                    await ref
                        .read(plannedExercisesProvider(dayId).notifier)
                        .deleteExerciseFromDay(plannedExercise.relationId);
                    return true;
                  } catch (_) {
                    if (!context.mounted) return false;
                    SnackBarError.show(
                      context,
                      'Could not delete exercise. Try again!',
                    );
                    return false;
                  }
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
                    ListTile(
                      dense: isTileDense,
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
                    if (i != plannedExercises.length - 1 ||
                        includeBottomDivider)
                      Divider(
                        height: 1,
                        color: AppColors.cardBorder,
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
