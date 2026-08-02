import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/card_flow/home_summary_card_flow.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/state/workout_focus_provider.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/home_summary_card.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/pick_next_workout_popup_menu.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WorkoutFocusCardFlow extends HomeSummaryCardFlow {
  const WorkoutFocusCardFlow();

  @override
  Widget buildHeader(BuildContext context, WidgetRef ref) {
    final sessionStatusAsync = ref.watch(activeSessionLifecycleProvider);

    return sessionStatusAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: HomeSummaryCardLoading.new,
      error: (_, _) => const HomeSummaryCardError(),
      data: (isSessionActive) {
        return HomeSummaryCardHeader(
          leading: isSessionActive
              ? Icon(
                  Icons.navigate_next_rounded,
                  size: 20,
                  color: AppColors.primary,
                )
              : const PickNextWorkoutPopupMenu(),
          title: isSessionActive ? 'Current session' : 'Next in cycle',
        );
      },
    );
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    final workoutFocusInfoAsync = ref.watch(workoutFocusProvider);

    return workoutFocusInfoAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: HomeSummaryCardLoading.new,
      error: (_, _) => const HomeSummaryCardError(),
      data: (workoutFocusInfo) {
        if (workoutFocusInfo.muscleGroups == null) {
          final message = workoutFocusInfo.isActiveQuickWorkout
              ? "This workout won't affect your split."
              : 'No exercises added yet. Start now and build as you go.';

          return HomeSummaryCardContent.message(
            primaryText: workoutFocusInfo.workoutName,
            secondaryText: message,
          );
        }

        final exerciseCount = workoutFocusInfo.exerciseCount ?? 0;

        return HomeSummaryCardContent.details(
          primaryText: workoutFocusInfo.workoutName,
          secondaryText: workoutFocusInfo.muscleGroups!,
          detailLeading: PhosphorIcon(
            PhosphorIcons.barbell(),
            size: 14,
            color: AppColors.primary,
          ),
          detailText:
              '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'} planned.',
        );
      },
    );
  }
}
