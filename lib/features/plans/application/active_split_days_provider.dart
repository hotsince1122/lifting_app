import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_id_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';

final activeSplitDaysProvider = FutureProvider<List<SplitDay>>((ref) async {
  final activeSplitId = await ref.watch(activeSplitIdProvider.future);

  if (activeSplitId == null) return const <SplitDay>[];

  return ref.watch(splitDaysController(activeSplitId).future);
});
