import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';

final class FakeLocalBackupRepository implements LocalBackupRepository {
  FakeLocalBackupRepository({
    required this.snapshot,
    this.exportException,
    this.exportFuture,
  });

  final BackupSnapshot snapshot;
  final Object? exportException;
  final Future<void>? exportFuture;

  int exportCallCount = 0;
  int importCallCount = 0;
  BackupSnapshot? lastImportedSnapshot;

  @override
  Future<BackupSnapshot> exportSnapshot() async {
    exportCallCount++;

    final pendingFuture = exportFuture;
    if (pendingFuture != null) {
      await pendingFuture;
    }

    final exception = exportException;
    if (exception != null) {
      throw exception;
    }

    return snapshot;
  }

  @override
  Future<void> importSnapshot(BackupSnapshot snapshot) async {
    importCallCount++;
    lastImportedSnapshot = snapshot;
  }
}

final class FakeCloudBackupRepository implements CloudBackupRepository {
  FakeCloudBackupRepository({
    this.metadataResult,
    this.metadataException,
    this.uploadResult,
    this.uploadException,
    this.uploadFuture,
    this.downloadResult,
  });

  final CloudBackupMetadata? metadataResult;
  final Object? metadataException;
  final CloudBackupMetadata? uploadResult;
  final Object? uploadException;
  final Future<CloudBackupMetadata>? uploadFuture;
  final BackupSnapshot? downloadResult;

  int metadataCallCount = 0;
  int uploadCallCount = 0;
  int downloadCallCount = 0;

  String? lastMetadataUserId;
  String? lastUploadUserId;
  String? lastDownloadUserId;
  BackupSnapshot? lastUploadedSnapshot;

  @override
  Future<CloudBackupMetadata?> getBackupMetadata({
    required String userId,
  }) async {
    metadataCallCount++;
    lastMetadataUserId = userId;

    final exception = metadataException;
    if (exception != null) {
      throw exception;
    }

    return metadataResult;
  }

  @override
  Future<CloudBackupMetadata> uploadBackup({
    required String userId,
    required BackupSnapshot snapshot,
  }) async {
    uploadCallCount++;
    lastUploadUserId = userId;
    lastUploadedSnapshot = snapshot;

    final pendingFuture = uploadFuture;
    if (pendingFuture != null) {
      return pendingFuture;
    }

    final exception = uploadException;
    if (exception != null) {
      throw exception;
    }

    final result = uploadResult;
    if (result == null) {
      throw StateError('No upload result configured.');
    }

    return result;
  }

  @override
  Future<BackupSnapshot?> downloadBackup({required String userId}) async {
    downloadCallCount++;
    lastDownloadUserId = userId;
    return downloadResult;
  }
}
