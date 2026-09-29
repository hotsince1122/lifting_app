abstract interface class LastBackupDateRepository {
  Future<DateTime?> read(String userId);
  Future<void> save(String userId, DateTime uploadedAt);
  Future<void> clear(String userId);
}
