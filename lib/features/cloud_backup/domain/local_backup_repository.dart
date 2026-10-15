import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';

abstract interface class LocalBackupRepository {
  Future<BackupSnapshot> exportSnapshot();

  Future<String?> loadOwnerUid();

  Future<void> claimForUid(String uid);

  Future<void> importSnapshot(
    BackupSnapshot snapshot, {
    required String ownerUid,
  });

  Future<bool> hasWorkoutProgress();

  Future<void> reassignOwnerUid({
    required String expectedOwnerUid,
    required String newUid,
  });

  Future<void> reassignOwnerUidIfNoWorkouts({
    required String expectedOwnerUid,
    required String newUid,
  });

  Future<bool> loadBackupPending();

  Future<void> setBackupPending(bool pending);
}
