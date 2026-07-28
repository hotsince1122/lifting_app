import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_days_provider.dart';

final pickedNextSessionProvider =
    AsyncNotifierProvider<PickedNextSessionController, String?>(
      PickedNextSessionController.new,
    );

class PickedNextSessionController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    await ref.watch(activeSplitDaysProvider.future);
    return null;
  }

  Future<void> changeNextSessionId(String dayId) async {
    state = AsyncData(dayId);
  }

  Future<void> consumeId() async {
    state = AsyncData(null);
  }
}
