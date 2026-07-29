import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_cycle_queries.dart';
import 'package:lifting_tracker_app/features/workouts/domain/next_session_preview.dart';

final nextSessionPreviewProvider = FutureProvider<NextSessionPreview>((
  ref,
) async {
  ref.watch(activeSessionLifecycleProvider);

  final activeSplitDays = await ref.watch(activeSplitDaysProvider.future);

  if (activeSplitDays.isEmpty) {
    throw StateError('Cannot find a planned session without an active split.');
  }

  final pickedDayId = await ref.watch(pickedNextSessionProvider.future);

  if (pickedDayId != null) {
    for (final splitDay in activeSplitDays) {
      if (splitDay.id == pickedDayId) {
        return NextSessionPreview(
          dayId: splitDay.id,
          workoutName: splitDay.name,
        );
      }
    }
  }

  final activeSplitDayIds = activeSplitDays
      .map((splitDay) => splitDay.id)
      .toList();
  final nextCycleIndex = await loadNextCycleIndex(activeSplitDayIds);
  final nextSplitDay = activeSplitDays.firstWhere(
    (splitDay) => splitDay.orderIndex == nextCycleIndex,
    orElse: () => activeSplitDays[nextCycleIndex],
  );

  return NextSessionPreview(
    dayId: nextSplitDay.id,
    workoutName: nextSplitDay.name,
  );
});
