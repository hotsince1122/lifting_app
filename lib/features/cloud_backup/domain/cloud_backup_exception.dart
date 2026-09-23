enum CloudBackupErrorCode {
  unauthenticated,
  permissionDenied,
  quotaExceeded,
  retryLimitExceeded,
  canceled,
  configurationError,
  transferIntegrityFailed,
  sizeLimitExceeded,
  unknown,
  emailNotVerified,
}

final class CloudBackupException implements Exception {
  const CloudBackupException(this.code);

  final CloudBackupErrorCode code;
}
