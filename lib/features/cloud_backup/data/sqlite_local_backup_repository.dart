import 'package:lifting_tracker_app/features/cloud_backup/data/export_snapshot_query.dart'
    as export_query;
import 'package:lifting_tracker_app/features/cloud_backup/data/import_snapshot_command.dart'
    as import_command;
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_commands.dart'
    as data_owner_commands;
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_queries.dart'
    as data_owner_queries;
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_pending_commands.dart'
    as pending_commands;
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_pending_queries.dart'
    as pending_queries;

final class SqliteLocalBackupRepository implements LocalBackupRepository {
  const SqliteLocalBackupRepository();

  @override
  Future<BackupSnapshot> exportSnapshot() {
    return export_query.exportSnapshot();
  }

  @override
  Future<void> importSnapshot(
    BackupSnapshot snapshot, {
    required String ownerUid,
  }) {
    return import_command.importSnapshot(snapshot, ownerUid: ownerUid);
  }

  @override
  Future<String?> loadOwnerUid() async {
    return data_owner_queries.loadLocalDataOwnerUid();
  }

  @override
  Future<void> claimForUid(String uid) async {
    return await data_owner_commands.claimLocalDataForUid(uid);
  }

  @override
  Future<bool> hasWorkoutProgress() async {
    return await data_owner_queries.hasLocalWorkoutProgress();
  }

  @override
  Future<void> reassignOwnerUid({
    required String expectedOwnerUid,
    required String newUid,
  }) async {
    return await data_owner_commands.reassignLocalDataOwnerUid(
      expectedOwnerUid: expectedOwnerUid,
      newUid: newUid,
    );
  }

  @override
  Future<void> reassignOwnerUidIfNoWorkouts({
    required String expectedOwnerUid,
    required String newUid,
  }) {
    return data_owner_commands.reassignLocalDataOwnerUidIfNoWorkouts(
      expectedOwnerUid: expectedOwnerUid,
      newUid: newUid,
    );
  }

  @override
  Future<bool> loadBackupPending() {
    return pending_queries.loadBackupPending();
  }

  @override
  Future<void> setBackupPending(bool pending) {
    return pending_commands.setBackupPending(pending);
  }
}
