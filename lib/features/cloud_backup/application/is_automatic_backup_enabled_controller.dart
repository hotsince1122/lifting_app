import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/is_automatic_backup_enabled_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/cloud_backup/data/is_automatic_backup_enabled_query.dart'
    as queries;

// final isAutomaticBackupEnabled = FutureProvider<bool>((ref) {
//   return isAutomaticBackupEnabledQuery();
// });

final isAutomaticBackupEnabledController =
    AsyncNotifierProvider<IsAutomaticBackupEnabledController, bool>(
      IsAutomaticBackupEnabledController.new,
    );

class IsAutomaticBackupEnabledController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return queries.isAutomaticBackupEnabled();
  }

  Future<void> switchValue(bool newValue) async {
    if (state.isLoading || !state.hasValue) return;

    final previousValue = state.requireValue;
    if (newValue == previousValue) return;

    state = AsyncData(newValue);

    state = const AsyncLoading();

    try {
      await commands.setNewValueForAutomaticBackup(newValue);

      if (!ref.mounted) return;
      state = AsyncData(newValue);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;

      state = AsyncData(previousValue);

      state = AsyncError(error, stackTrace);
    }
  }
}
