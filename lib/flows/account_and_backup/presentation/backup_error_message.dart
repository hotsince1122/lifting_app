import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

typedef BackupErrorMessage = ({String title, String description});

BackupErrorMessage backupErrorMessage(Object? error) {
  final code = error is CloudBackupException ? error.code : null;

  return switch (code) {
    CloudBackupErrorCode.unauthenticated => (
      title: 'Sign in required',
      description: 'Sign in again to access your cloud backup.',
    ),
    CloudBackupErrorCode.emailNotVerified => (
      title: 'Verify your email',
      description: 'Verify your email to enable cloud backup.',
    ),
    CloudBackupErrorCode.permissionDenied => (
      title: 'Cloud backup access denied',
      description: 'Your account could not access this backup.',
    ),
    CloudBackupErrorCode.quotaExceeded ||
    CloudBackupErrorCode.configurationError => (
      title: 'Cloud backup unavailable',
      description:
          'The backup service is currently unavailable. Please try again later.',
    ),
    CloudBackupErrorCode.retryLimitExceeded => (
      title: 'Cloud backup request timed out',
      description: 'Check your internet connection and try again.',
    ),
    CloudBackupErrorCode.canceled => (
      title: 'Cloud backup request canceled',
      description: 'The operation was canceled. You can try again.',
    ),
    CloudBackupErrorCode.transferIntegrityFailed => (
      title: 'Backup transfer failed',
      description: 'The transfer could not be verified. Please try again.',
    ),
    CloudBackupErrorCode.sizeLimitExceeded => (
      title: 'Backup too large',
      description: 'Your training data exceeds the supported backup size.',
    ),
    CloudBackupErrorCode.unknown || null => (
      title: 'Could not complete cloud backup request',
      description: 'Something went wrong. Please try again.',
    ),
  };
}
