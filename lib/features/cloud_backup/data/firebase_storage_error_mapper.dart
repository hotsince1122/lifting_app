import 'package:firebase_core/firebase_core.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

CloudBackupException mapFirebaseStorageException(FirebaseException exception) {
  switch (exception.code) {
    case 'unauthenticated':
      return const CloudBackupException(CloudBackupErrorCode.unauthenticated);

    case 'unauthorized':
      return const CloudBackupException(CloudBackupErrorCode.permissionDenied);

    case 'quota-exceeded':
      return const CloudBackupException(CloudBackupErrorCode.quotaExceeded);

    case 'retry-limit-exceeded':
      return const CloudBackupException(CloudBackupErrorCode.retryLimitExceeded);

    case 'canceled':
      return const CloudBackupException(CloudBackupErrorCode.canceled);

    case 'bucket-not-found':
      return const CloudBackupException(CloudBackupErrorCode.configurationError);

    case 'project-not-found':
      return const CloudBackupException(CloudBackupErrorCode.configurationError);

    case 'no-default-bucket':
      return const CloudBackupException(CloudBackupErrorCode.configurationError);

    case 'invalid-checksum':
      return const CloudBackupException(CloudBackupErrorCode.transferIntegrityFailed);

    case 'server-file-wrong-size':
      return const CloudBackupException(CloudBackupErrorCode.transferIntegrityFailed);

    default:
      return const CloudBackupException(CloudBackupErrorCode.unknown);
  }
}
