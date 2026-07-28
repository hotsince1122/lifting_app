import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _setupStatusKey = 'did_user_finish_setup';

final setupCompletionProvider =
    AsyncNotifierProvider<SetupCompletionController, bool>(
      SetupCompletionController.new,
    );

class SetupCompletionController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupStatusKey) ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    final didSave = await prefs.setBool(_setupStatusKey, true);

    if (!didSave) {
      throw StateError('Could not persist onboarding completion.');
    }

    state = const AsyncData(true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final didSave = await prefs.setBool(_setupStatusKey, false);

    if (!didSave) {
      throw StateError('Could not reset onboarding completion.');
    }

    state = const AsyncData(false);
  }
}
