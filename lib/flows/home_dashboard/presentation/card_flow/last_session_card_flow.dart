import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/application/last_workout_completed_provider.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/card_flow/home_summary_card_flow.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/home_summary_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LastSessionCardFlow extends HomeSummaryCardFlow {
  const LastSessionCardFlow();

  @override
  Widget buildHeader(BuildContext context, WidgetRef ref) {
    return HomeSummaryCardHeader(
      leading: PhosphorIcon(
        PhosphorIcons.clockCounterClockwise(),
        size: 20,
        color: AppColors.primary,
      ),
      title: 'Last session',
    );
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    final lastWorkoutCompletedAsync = ref.watch(lastWorkoutCompletedProvider);

    return lastWorkoutCompletedAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: HomeSummaryCardLoading.new,
      error: (_, _) => const HomeSummaryCardError(),
      data: (lastWorkoutCompleted) {
        if (lastWorkoutCompleted == null) {
          return const HomeSummaryCardContent.message(
            primaryText: 'No sessions yet.',
            secondaryText: 'Your latest workout will appear here.',
          );
        }

        final workoutDurationMinutes =
            lastWorkoutCompleted.workoutDuration ~/ Duration.secondsPerMinute;
        final exerciseCount = lastWorkoutCompleted.exerciseCount;

        return HomeSummaryCardContent.details(
          primaryText: lastWorkoutCompleted.workoutName,
          secondaryText: '$workoutDurationMinutes min workout',
          detailText:
              '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'} finished',
        );
      },
    );
  }
}
