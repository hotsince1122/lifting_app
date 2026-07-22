import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final pickedNextSessionProvider =
    AsyncNotifierProvider<PickedNextSessionNotifier, String?>(
      PickedNextSessionNotifier.new,
    );

class PickedNextSessionNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    return null;
  }

  Future<void> changeNextSessionId(String dayId) async {
    state = AsyncData(dayId);
  }

  Future<void> consumeId() async {
    state = AsyncData(null);
  }
}
