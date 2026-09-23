final class CloudBackupMetadata {
  const CloudBackupMetadata({
    required this.uploadedAt,
    required this.sizeBytes,
  });

  final DateTime uploadedAt;
  final int sizeBytes;
}
