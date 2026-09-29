import 'package:lifting_tracker_app/features/cloud_backup/domain/last_backup_date_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesLastBackupDateRepository
    implements LastBackupDateRepository {
  SharedPreferencesLastBackupDateRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _keyPrefix = 'cloud_backup.last_uploaded_at.v1.';

  final SharedPreferencesAsync _preferences;

  String _key(String userId) => '$_keyPrefix$userId';

  @override
  Future<DateTime?> read(String userId) async {
    final encoded = await _preferences.getString(_key(userId));
    if (encoded == null) return null;
    return DateTime.tryParse(encoded)?.toUtc();
  }

  @override
  Future<void> save(String userId, DateTime uploadedAt) {
    return _preferences.setString(
      _key(userId),
      uploadedAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear(String userId) => _preferences.remove(_key(userId));
}
