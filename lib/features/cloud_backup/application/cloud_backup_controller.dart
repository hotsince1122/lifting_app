import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

final cloudBackupControllerProvider =
    AsyncNotifierProvider<CloudBackupController, CloudBackupMetadata?>(
      CloudBackupController.new,
    );

class CloudBackupController extends AsyncNotifier<CloudBackupMetadata?> {
  @override
  Future<CloudBackupMetadata?> build() async {
    final user = await ref.watch(authStateProvider.future);

    if (user == null || !user.isEmailVerified) {
      return null;
    }

    final repository = ref.watch(cloudBackupRepositoryProvider);

    return repository.getBackupMetadata(userId: user.id);
  }

  Future<void> backupNow() async {
    if (state.isLoading) return;

    state = const AsyncLoading<CloudBackupMetadata?>();

    final nextState = await AsyncValue.guard<CloudBackupMetadata?>(() async {
      final user = await ref.read(authStateProvider.future);

      if (user == null) {
        throw const CloudBackupException(CloudBackupErrorCode.unauthenticated);
      }

      if (!user.isEmailVerified) {
        throw const CloudBackupException(CloudBackupErrorCode.emailNotVerified);
      }

      final localRepository = ref.read(localBackupRepositoryProvider);
      final cloudRepository = ref.read(cloudBackupRepositoryProvider);

      final snapshot = await localRepository.exportSnapshot();

      return cloudRepository.uploadBackup(userId: user.id, snapshot: snapshot);
    });

    state = nextState;
  }
}
