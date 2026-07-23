import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/application/exercise_and_sets/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/add_exercises_to_workout.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/workout_exercise_card.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/app_bar/active_workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/app_bar/edit_workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/app_bar/workout_session_app_bar.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/app_bar/workout_editor_flow.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/session_summary_card.dart';

class WorkoutEditorPage extends ConsumerWidget {
  const WorkoutEditorPage(this.workoutSessionId, this.flow, {super.key});

  const WorkoutEditorPage.active(this.workoutSessionId, {super.key})
    : flow = const ActiveWorkoutEditorFlow();

  const WorkoutEditorPage.edit(this.workoutSessionId, {super.key})
    : flow = const EditWorkoutEditorFlow();

  final int workoutSessionId;
  final WorkoutEditorFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double horizontalPadding = 18;
    final double spaceBetween = 24;
    final double bottomPadding = 32;

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
        return Scaffold(
          appBar: WorkoutSessionAppBar(workoutSessionId, flow),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    hp(SessionSummaryCard(flow, sessionId: workoutSessionId)),
                    SizedBox(height: spaceBetween),
                    for (int i = 0; i < exerciseAndSets.length; i++) ...[
                      WorkoutExerciseCard(
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
                    hp(AddExercisesToWorkout(workoutSessionId)),
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
