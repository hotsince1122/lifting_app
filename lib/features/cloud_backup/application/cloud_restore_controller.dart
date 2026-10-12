import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/invalidate_restored_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

enum RestoreResult { noBackup, restored }

final cloudRestoreControllerProvider =
    AsyncNotifierProvider<CloudRestoreController, RestoreResult?>(
      CloudRestoreController.new,
    );

class CloudRestoreController extends AsyncNotifier<RestoreResult?> {
  Timer? _clearNoticeTimer;

  @override
  FutureOr<RestoreResult?> build() {
    ref.onDispose(() => _clearNoticeTimer?.cancel());
    return null;
  }

  Future<void> restoreNow() async {
    if (state.isLoading) return;

    _clearNoticeTimer?.cancel();
    state = const AsyncLoading<RestoreResult?>();

    final nextState = await AsyncValue.guard<RestoreResult?>(() async {
      final user = await ref.read(authStateProvider.future);

      if (user == null) {
        throw const CloudBackupException(CloudBackupErrorCode.unauthenticated);
      }

      if (!user.isEmailVerified) {
        throw const CloudBackupException(CloudBackupErrorCode.emailNotVerified);
      }

      final cloudRepository = ref.read(cloudBackupRepositoryProvider);

      final snapshot = await cloudRepository.downloadBackup(userId: user.id);

      if (snapshot == null) return RestoreResult.noBackup;

      final localRepository = ref.read(localBackupRepositoryProvider);

      final currentUser = await ref.read(authStateProvider.future);
      if (currentUser == null || currentUser.id != user.id) {
        throw const CloudBackupException(CloudBackupErrorCode.canceled);
      }

      await localRepository.importSnapshot(snapshot, ownerUid: user.id);

      return RestoreResult.restored;
    });

    state = nextState;
    if (nextState.value == RestoreResult.restored) {
      invalidateRestoredData(ref);
    }
    _clearNoticeTimer = Timer(const Duration(seconds: 8), () {
      if (ref.mounted) {
        state = const AsyncData<RestoreResult?>(null);
      }
    });
  }
}
