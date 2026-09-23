import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';

abstract interface class LocalBackupRepository {
  Future<BackupSnapshot> exportSnapshot();

  Future<void> importSnapshot(BackupSnapshot snapshot);
}
