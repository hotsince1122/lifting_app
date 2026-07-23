import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/widgets/homescreen/last_session_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/workout_focus_section/workout_focus_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/progress_spotlight.dart';
import 'package:lifting_tracker_app/widgets/homescreen/quick_workout.dart';
import 'package:lifting_tracker_app/widgets/homescreen/start_session.dart';
import 'package:lifting_tracker_app/widgets/homescreen/week_progress.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSessionAlreadyActiveAsync = ref.watch(
      activeSessionLifecycleProvider,
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeekProgress(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: LastSessionSection()),
                const SizedBox(width: 16),
                Expanded(child: WorkoutFocusSection()),
              ],
            ),
            const SizedBox(height: 16),
            ProgressSpotlight(),
            const SizedBox(height: 16),

            isSessionAlreadyActiveAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('An error has occured! Try again.')),
              data: (isSessionAlreadyActive) {
                return isSessionAlreadyActive
                    ? StartSession()
                    : Row(
                        children: [
                          Expanded(flex: 3, child: QuickWorkout()),
                          const SizedBox(width: 8),
                          Expanded(flex: 7, child: StartSession()),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
