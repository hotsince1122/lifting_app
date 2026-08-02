import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/view_data/workout_set_focus_nodes.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/add_exercises_to_workout.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_exercise_card.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/editor/active_workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/app_bar/workout_session_app_bar.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/editor/workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/session_summary_card.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_keyboard_toolbar.dart';

class WorkoutEditorPage extends ConsumerWidget {
  const WorkoutEditorPage(this.workoutSessionId, this.flow, {super.key});

  const WorkoutEditorPage.active(this.workoutSessionId, {super.key})
    : flow = const ActiveWorkoutEditorFlow();

  final int workoutSessionId;
  final WorkoutEditorFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double horizontalPadding = AppSpacing.s16;
    final double spaceBetween = AppSpacing.s24;
    final double bottomPadding = AppSpacing.s32;

    final exercisesAndSetsAsync = ref.watch(
      workoutSessionExercisesProvider(workoutSessionId),
    );

    Widget hp(Widget child) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: child,
      );
    }

    return exercisesAndSetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured. Try again.')),
      data: (exerciseAndSets) {
        return _WorkoutFocusRegistry(
          exercises: exerciseAndSets,
          builder: (context, focusNodesBySetId) {
            final orderedFocusNodes = <FocusNode>[];

            for (final exercise in exerciseAndSets) {
              for (final set in exercise.sets) {
                final setId = set.workoutSessionSetId;

                if (setId == null) continue;

                final focusNodes = focusNodesBySetId[setId];

                if (focusNodes == null) continue;

                orderedFocusNodes.addAll([
                  focusNodes.weight,
                  focusNodes.reps,
                  focusNodes.notes,
                ]);
              }
            }

            final keyboardActionItems = [
              for (final focusNode in orderedFocusNodes)
                KeyboardActionsItem(
                  focusNode: focusNode,
                  displayArrows: false,
                  displayDoneButton: false,
                  toolbarButtons: [
                    (currentFocusNode) {
                      final currentIndex = orderedFocusNodes.indexWhere(
                        (node) => identical(node, currentFocusNode),
                      );

                      final canGoPrevious = currentIndex > 0;
                      final canGoNext =
                          currentIndex >= 0 &&
                          currentIndex < orderedFocusNodes.length - 1;

                      return Expanded(
                        child: WorkoutKeyboardToolbar(
                          onPrevious: canGoPrevious
                              ? () {
                                  orderedFocusNodes[currentIndex - 1]
                                      .requestFocus();
                                }
                              : null,
                          onNext: canGoNext
                              ? () {
                                  orderedFocusNodes[currentIndex + 1]
                                      .requestFocus();
                                }
                              : null,
                          onDismiss: currentFocusNode.unfocus,
                        ),
                      );
                    },
                  ],
                ),
            ];

            return Scaffold(
              appBar: WorkoutSessionAppBar(workoutSessionId, flow),
              body: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: KeyboardActions(
                    autoScroll: false,
                    barSize: 60,
                    config: KeyboardActionsConfig(
                      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
                      nextFocus: false,
                      keyboardBarColor: AppColors.card,
                      keyboardBarElevation: 0,
                      keyboardSeparatorColor: AppColors.cardBorder,
                      actions: keyboardActionItems,
                    ),
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      child: Column(
                        children: [
                          hp(
                            SessionSummaryCard(
                              flow,
                              sessionId: workoutSessionId,
                            ),
                          ),
                          SizedBox(height: spaceBetween),
                          for (int i = 0; i < exerciseAndSets.length; i++) ...[
                            WorkoutExerciseCard(
                              exerciseAndSets[i],
                              workoutSessionId,
                              horizontalPadding,
                              focusNodesBySetId: focusNodesBySetId,
                              key: ValueKey((
                                exerciseAndSets[i].catalogExercise.id,
                                exerciseAndSets[i].orderIndex,
                              )),
                            ),
                            SizedBox(height: spaceBetween),
                          ],
                          hp(AddExercisesToWorkout(workoutSessionId)),
                          const SizedBox(height: AppSpacing.s12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WorkoutFocusRegistry extends StatefulWidget {
  const _WorkoutFocusRegistry({required this.exercises, required this.builder});

  final List<WorkoutExercise> exercises;

  final Widget Function(
    BuildContext context,
    Map<int, WorkoutSetFocusNodes> focusNodesBySetId,
  )
  builder;

  @override
  State<_WorkoutFocusRegistry> createState() => _WorkoutFocusRegistryState();
}

class _WorkoutFocusRegistryState extends State<_WorkoutFocusRegistry> {
  final Map<int, WorkoutSetFocusNodes> _focusNodesBySetId = {};

  @override
  void initState() {
    super.initState();
    _synchronizeFocusNodes();
  }

  @override
  void didUpdateWidget(covariant _WorkoutFocusRegistry oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeFocusNodes();
  }

  void _synchronizeFocusNodes() {
    final activeSetIds = <int>{};

    for (final exercise in widget.exercises) {
      for (final set in exercise.sets) {
        final setId = set.workoutSessionSetId;

        if (setId == null) continue;

        activeSetIds.add(setId);

        _focusNodesBySetId.putIfAbsent(
          setId,
          () => WorkoutSetFocusNodes(setId),
        );
      }
    }

    final removedSetIds = _focusNodesBySetId.keys
        .where((setId) => !activeSetIds.contains(setId))
        .toList();

    for (final setId in removedSetIds) {
      final removedNodes = _focusNodesBySetId.remove(setId);

      removedNodes?.unfocus();
      removedNodes?.dispose();
    }
  }

  @override
  void dispose() {
    for (final focusNodes in _focusNodesBySetId.values) {
      focusNodes.dispose();
    }

    _focusNodesBySetId.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, Map.unmodifiable(_focusNodesBySetId));
  }
}
