import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/add_exercises_card.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_and_sets_card.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/active_workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/edit_workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_session_app_bar.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/session_summary_card.dart';

class WorkoutEditorScreen extends ConsumerWidget {
  const WorkoutEditorScreen(this.workoutSessionId, this.flow, {super.key});

  const WorkoutEditorScreen.active(this.workoutSessionId, {super.key})
    : flow = const ActiveWorkoutEditorFlow();

  const WorkoutEditorScreen.edit(this.workoutSessionId, {super.key})
    : flow = const EditWorkoutEditorFlow();

  final int workoutSessionId;
  final WorkoutEditorFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double horizontalPadding = 18;
    final double spaceBetween = 24;
    final double bottomPadding = 32;

    final exercisesAndSetsAsync = ref.watch(
      exercisesAndSetsProvider(workoutSessionId),
    );

    Widget hp(Widget child) {
      return Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: horizontalPadding),
        child: child,
      );
    }

    return exercisesAndSetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured. Try again.')),
      data: (exerciseAndSets) {
        return Scaffold(
          appBar: WorkoutSessionAppBar(workoutSessionId, flow),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    hp(SessionSummaryCard(sessionId: workoutSessionId)),
                    SizedBox(height: spaceBetween),
                    for (int i = 0; i < exerciseAndSets.length; i++) ...[
                      ExerciseAndSetsCard(
                        exerciseAndSets[i],
                        workoutSessionId,
                        horizontalPadding,
                        key: ValueKey((
                          exerciseAndSets[i].id,
                          exerciseAndSets[i].orderIndex,
                        )),
                      ),
                      SizedBox(height: spaceBetween),
                    ],
                    hp(AddExercisesCard(workoutSessionId)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
