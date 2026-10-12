import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_restore_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

enum ProgressProtectionNoticeContent {
  guest,
  verificationRequired,
  backupError,
  restoreLoading,
  restoreNoBackup,
  restoreError,
  restoreSuccess,
}

final progressProtectionNoticeProvider =
    FutureProvider<ProgressProtectionNoticeContent?>((ref) async {
      final authState = await ref.watch(authStateProvider.future);

      if (authState == null) return ProgressProtectionNoticeContent.guest;

      if (!authState.isEmailVerified) {
        return ProgressProtectionNoticeContent.verificationRequired;
      }

      final restoreState = ref.watch(cloudRestoreControllerProvider);
      if (restoreState.isLoading) {
        return ProgressProtectionNoticeContent.restoreLoading;
      }
      if (restoreState.hasError) {
        final error = restoreState.error;
        if (error is CloudBackupException &&
            error.code == CloudBackupErrorCode.emailNotVerified) {
          return ProgressProtectionNoticeContent.verificationRequired;
        }
        return ProgressProtectionNoticeContent.restoreError;
      }
      switch (restoreState.value) {
        case RestoreResult.noBackup:
          return ProgressProtectionNoticeContent.restoreNoBackup;
        case RestoreResult.restored:
          return ProgressProtectionNoticeContent.restoreSuccess;
        case null:
          break;
      }

      final backupState = ref.watch(cloudBackupControllerProvider);
      if (!backupState.isLoading && backupState.hasError) {
        final error = backupState.error;
        if (error is CloudBackupException &&
            error.code == CloudBackupErrorCode.emailNotVerified) {
          return ProgressProtectionNoticeContent.verificationRequired;
        }
        return ProgressProtectionNoticeContent.backupError;
      }

      return null;
    });
