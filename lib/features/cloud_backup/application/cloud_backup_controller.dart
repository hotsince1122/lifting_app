import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

final cloudBackupControllerProvider =
    AsyncNotifierProvider<CloudBackupController, CloudBackupMetadata?>(
      CloudBackupController.new,
      retry: (_, _) => null,
    );

class CloudBackupController extends AsyncNotifier<CloudBackupMetadata?> {
  int _generation = 0;

  @override
  Future<CloudBackupMetadata?> build() async {
    final generation = ++_generation;
    // A rebuild can reuse this notifier while its old Futures are still running.
    ref.onDispose(() => _generation++);
    final user = await ref.watch(authStateProvider.future);

    if (!_isCurrent(generation)) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }
    if (user == null || !user.isEmailVerified) {
      return null;
    }

    final repository = ref.watch(cloudBackupRepositoryProvider);

    final metadata = await repository
        .getBackupMetadata(userId: user.id)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw const CloudBackupException(
            CloudBackupErrorCode.retryLimitExceeded,
          ),
        );
    _requireCurrentUser(generation, user.id);
    await _updateLocalDate(generation, user.id, metadata?.uploadedAt);
    _requireCurrentUser(generation, user.id);
    return metadata;
  }

  Future<void> backupNow() async {
    if (state.isLoading) return;

    final generation = _generation;
    state = const AsyncLoading<CloudBackupMetadata?>();

    final nextState = await AsyncValue.guard<CloudBackupMetadata?>(() async {
      final user = await ref.read(authStateProvider.future);

      if (user == null) {
        throw const CloudBackupException(CloudBackupErrorCode.unauthenticated);
      }

      if (!user.isEmailVerified) {
        throw const CloudBackupException(CloudBackupErrorCode.emailNotVerified);
      }

      _requireCurrentUser(generation, user.id);
      final localRepository = ref.read(localBackupRepositoryProvider);
      final cloudRepository = ref.read(cloudBackupRepositoryProvider);

      final ownerUid = await localRepository.loadOwnerUid();
      _requireCurrentUser(generation, user.id);

      // Only the sign-in resolution flow may claim or transfer local data.
      if (ownerUid != user.id) {
        throw StateError('Resolve local data ownership before backing up.');
      }

      final snapshot = await localRepository.exportSnapshot();
      _requireCurrentUser(generation, user.id);

      // Export can take time; ownership must still match before sending data.
      final currentOwnerUid = await localRepository.loadOwnerUid();
      _requireCurrentUser(generation, user.id);
      if (currentOwnerUid != user.id) {
        throw const CloudBackupException(CloudBackupErrorCode.canceled);
      }

      final metadata = await cloudRepository.uploadBackup(
        userId: user.id,
        snapshot: snapshot,
      );
      _requireCurrentUser(generation, user.id);
      await _updateLocalDate(generation, user.id, metadata.uploadedAt);
      _requireCurrentUser(generation, user.id);
      return metadata;
    });

    // Success and failure from an older session must not replace the new state.
    if (_isCurrent(generation)) state = nextState;
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  void _requireCurrentUser(int generation, String expectedUid) {
    if (!_isCurrent(generation)) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null || user.id != expectedUid || !user.isEmailVerified) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }
  }

  Future<void> _updateLocalDate(
    int generation,
    String userId,
    DateTime? uploadedAt,
  ) async {
    try {
      final cache = ref.read(lastBackupDateRepositoryProvider);
      if (uploadedAt == null) {
        await cache.clear(userId);
      } else {
        await cache.save(userId, uploadedAt);
      }
      if (_isCurrent(generation)) {
        ref.invalidate(lastBackupDateProvider(userId));
      }
    } catch (_) {
      // A cache failure must not turn a successful cloud operation into an error.
    }
  }
}
