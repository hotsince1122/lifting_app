import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

enum ProgressProtectionNoticeContent {
  guest,
  verificationRequired,
  backupError,
}

final progressProtectionNoticeProvider =
    FutureProvider<ProgressProtectionNoticeContent?>((ref) async {
      final authState = await ref.watch(authStateProvider.future);

      if (authState == null) return ProgressProtectionNoticeContent.guest;

      if (!authState.isEmailVerified) {
        return ProgressProtectionNoticeContent.verificationRequired;
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
