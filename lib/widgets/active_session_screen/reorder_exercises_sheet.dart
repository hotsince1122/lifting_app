import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class ReorderExercisesSheet extends ConsumerStatefulWidget {
  const ReorderExercisesSheet(this.screenWidth, this.sessionId, {super.key});

  final double screenWidth;
  final int sessionId;

  static Future<void> openSheet(
    BuildContext context,
    double screenWidth,
    int sessionId,
  ) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => ReorderExercisesSheet(screenWidth, sessionId),
    );
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      ReorderExercisesSheetState();
}

class ReorderExercisesSheetState extends ConsumerState<ReorderExercisesSheet> {
  Object _exerciseKey(Exercise exercise) {
    final firstSetId = exercise.sets.isEmpty
        ? null
        : exercise.sets.first.activeSessionSetId;

    return firstSetId ?? '${exercise.id}-${exercise.orderIndex}';
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesAndSetsProvider(widget.sessionId),
    );

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('An error has occured! Try again.'),
      data: (exercises) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                width: widget.screenWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.card.withAlpha(253),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Reorder Exercises',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                iconSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: DragBoundary(
                          child: ReorderableListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: exercises.length,
                            onReorder: (oldIndex, newIndex) async {
                              await ref
                                  .read(
                                    exercisesAndSetsProvider(
                                      widget.sessionId,
                                    ).notifier,
                                  )
                                  .reorderExercises(oldIndex, newIndex);
                            },
                            dragBoundaryProvider: (context) =>
                                DragBoundary.forRectOf(context),
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, i) {
                              final exercise = exercises[i];

                              final label =
                                  exercise.name[0] + exercise.name.substring(1);

                              return Dismissible(
                                key: ValueKey(_exerciseKey(exercise)),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) async {
                                  await ref
                                      .read(
                                        exercisesAndSetsProvider(
                                          widget.sessionId,
                                        ).notifier,
                                      )
                                      .deleteExercise(
                                        exercise.id,
                                        exercise.orderIndex!,
                                      );
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
                                      color: AppColors.cardBorder,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                      title: Text(
                                        label,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      trailing:
                                          ReorderableDelayedDragStartListener(
                                            index: i,
                                            child: const SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: Icon(Icons.drag_handle),
                                            ),
                                          ),
                                    ),
                                    Divider(
                                      height: 0.5,
                                      color: AppColors.cardBorder,
                                      indent: 16,
                                      endIndent: 16,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
