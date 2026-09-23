import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/firebase_storage_error_mapper.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

void main() {
  group('mapFirebaseStorageException', () {
    const expectedCodes = <String, CloudBackupErrorCode>{
      'unauthenticated': CloudBackupErrorCode.unauthenticated,
      'unauthorized': CloudBackupErrorCode.permissionDenied,
      'quota-exceeded': CloudBackupErrorCode.quotaExceeded,
      'retry-limit-exceeded': CloudBackupErrorCode.retryLimitExceeded,
      'canceled': CloudBackupErrorCode.canceled,
      'bucket-not-found': CloudBackupErrorCode.configurationError,
      'project-not-found': CloudBackupErrorCode.configurationError,
      'no-default-bucket': CloudBackupErrorCode.configurationError,
      'invalid-checksum': CloudBackupErrorCode.transferIntegrityFailed,
      'server-file-wrong-size': CloudBackupErrorCode.transferIntegrityFailed,
    };

    for (final entry in expectedCodes.entries) {
      test('maps ${entry.key} to ${entry.value.name}', () {
        // Arrange
        final exception = FirebaseException(
          plugin: 'firebase_storage',
          code: entry.key,
        );

        // Act
        final result = mapFirebaseStorageException(exception);

        // Assert
        expect(result.code, entry.value);
      });
    }

    test('maps an unrecognized error code to unknown', () {
      // Arrange
      final exception = FirebaseException(
        plugin: 'firebase_storage',
        code: 'future-storage-error',
      );

      // Act
      final result = mapFirebaseStorageException(exception);

      // Assert
      expect(result.code, CloudBackupErrorCode.unknown);
    });
  });
}
