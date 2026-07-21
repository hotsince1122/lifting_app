import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_id.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';

final activeSplitDaysProvider = FutureProvider<List<SplitDay>>((ref) async {
  final activeSplitId = await ref.watch(activeSplitIdProvider.future);

  if (activeSplitId == null) return const <SplitDay>[];

  return ref.watch(splitDaysProvider(activeSplitId).future);
});
