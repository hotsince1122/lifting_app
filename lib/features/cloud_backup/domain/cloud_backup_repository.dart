import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

abstract interface class CloudBackupRepository {
  Future<CloudBackupMetadata> uploadBackup({
    required String userId,
    required BackupSnapshot snapshot,
  });

  Future<BackupSnapshot?> downloadBackup({required String userId});

  Future<CloudBackupMetadata?> getBackupMetadata({required String userId});
}
