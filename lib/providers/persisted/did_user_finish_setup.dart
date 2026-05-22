import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _steupStatusKey = 'did_user_finish_setup';

final didUserFinishSetupProvider = AsyncNotifierProvider<DidUserFinishSetupNotifier, bool>(
  DidUserFinishSetupNotifier.new,
);

class DidUserFinishSetupNotifier extends AsyncNotifier<bool> {

  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();

    final didUserFinishSetup = prefs.getBool(_steupStatusKey);
    if(didUserFinishSetup == null || didUserFinishSetup == false) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> userFinishedSetup () async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_steupStatusKey, true); 
  }

  Future<void> reset () async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_steupStatusKey, false);
  }
}