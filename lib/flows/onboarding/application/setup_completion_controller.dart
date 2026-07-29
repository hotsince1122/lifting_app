import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_queries.dart'
    as queries;

import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_commands.dart'
    as commands;

final setupCompletionProvider =
    AsyncNotifierProvider<SetupCompletionController, bool>(
      SetupCompletionController.new,
    );

class SetupCompletionController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    return await queries.loadSetupCompletion();
  }

  Future<void> complete() async {
    await commands.setAsCompleted();

    state = const AsyncData(true);
  }

  Future<void> reset() async {
    await commands.reset();

    state = const AsyncData(false);
  }
}
