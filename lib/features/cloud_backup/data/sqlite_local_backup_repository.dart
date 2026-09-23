import 'package:lifting_tracker_app/features/cloud_backup/data/export_snapshot_query.dart'
    as export_query;
import 'package:lifting_tracker_app/features/cloud_backup/data/import_snapshot_command.dart'
    as import_command;
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';

final class SqliteLocalBackupRepository implements LocalBackupRepository {
  const SqliteLocalBackupRepository();

  @override
  Future<BackupSnapshot> exportSnapshot() {
    return export_query.exportSnapshot();
  }

  @override
  Future<void> importSnapshot(BackupSnapshot snapshot) {
    return import_command.importSnapshot(snapshot);
  }
}
