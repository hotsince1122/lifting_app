import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/last_session_section.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/workout_focus_section.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/progress_spotlight.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/quick_workout.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/start_session.dart';
import 'package:lifting_tracker_app/features/progress/presentation/widgets/week_progress.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSessionAlreadyActiveAsync = ref.watch(
      activeSessionLifecycleProvider,
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              physics: ScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  sliver: SliverList.list(
                    children: [
                      WeekProgress(),
                      const SizedBox(height: AppSpacing.s24),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.decelerate,
                        alignment: Alignment.topCenter,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: LastSessionSection()),
                              const SizedBox(width: AppSpacing.s16),
                              Expanded(child: WorkoutFocusSection()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    0,
                  ),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: ProgressSpotlight(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: AppSpacing.s16),
            child: isSessionAlreadyActiveAsync.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true,
              loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) =>
                  const Center(child: Text('An error has occured! Try again.')),
              data: (isSessionAlreadyActive) {
                return isSessionAlreadyActive
                    ? StartSession()
                    : Row(
                        children: [
                          Expanded(flex: 3, child: QuickWorkout()),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(flex: 7, child: StartSession()),
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
        ],
      ),
    );
  }
}
