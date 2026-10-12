import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/last_backup_date_repository.dart';

final class FakeLastBackupDateRepository implements LastBackupDateRepository {
  final dates = <String, DateTime>{};
  bool throwOnWrite = false;

  @override
  Future<DateTime?> read(String userId) async => dates[userId];

  @override
  Future<void> save(String userId, DateTime uploadedAt) async {
    if (throwOnWrite) throw StateError('Cache unavailable');
    dates[userId] = uploadedAt;
  }

  @override
  Future<void> clear(String userId) async {
    if (throwOnWrite) throw StateError('Cache unavailable');
    dates.remove(userId);
  }
}

final class FakeLocalBackupRepository implements LocalBackupRepository {
  FakeLocalBackupRepository({
    required this.snapshot,
    this.ownerUid,
    this.hasWorkoutProgressValue = false,
    this.exportException,
    this.exportFuture,
    this.importException,
    this.importFuture,
  });

  final BackupSnapshot snapshot;
  String? ownerUid;
  bool hasWorkoutProgressValue;
  final Object? exportException;
  final Future<void>? exportFuture;
  final Object? importException;
  final Future<void>? importFuture;

  int exportCallCount = 0;
  int importCallCount = 0;
  int loadOwnerCallCount = 0;
  int claimCallCount = 0;
  int hasWorkoutProgressCallCount = 0;
  int reassignOwnerCallCount = 0;
  int reassignOwnerIfNoWorkoutsCallCount = 0;
  String? lastClaimedUid;
  String? lastExpectedOwnerUid;
  String? lastReassignedOwnerUid;
  BackupSnapshot? lastImportedSnapshot;
  String? lastImportedOwnerUid;

  @override
  Future<String?> loadOwnerUid() async {
    loadOwnerCallCount++;
    return ownerUid;
  }

  @override
  Future<void> claimForUid(String uid) async {
    claimCallCount++;
    lastClaimedUid = uid;
    if (uid.trim().isEmpty) throw ArgumentError('UID cannot be empty.');
    if (ownerUid != null && ownerUid != uid) {
      throw StateError('Local data belongs to another account.');
    }
    ownerUid = uid;
  }

  @override
  Future<bool> hasWorkoutProgress() async {
    hasWorkoutProgressCallCount++;
    return hasWorkoutProgressValue;
  }

  @override
  Future<void> reassignOwnerUid({
    required String expectedOwnerUid,
    required String newUid,
  }) async {
    reassignOwnerCallCount++;
    lastExpectedOwnerUid = expectedOwnerUid;
    lastReassignedOwnerUid = newUid;
    if (expectedOwnerUid.trim().isEmpty || newUid.trim().isEmpty) {
      throw ArgumentError('UIDs cannot be empty.');
    }
    if (expectedOwnerUid.trim() == newUid.trim()) {
      throw ArgumentError('UIDs cannot be the same.');
    }
    if (ownerUid != expectedOwnerUid) {
      throw StateError('Local data owner does not match the expected UID.');
    }
    ownerUid = newUid;
  }

  @override
  Future<void> reassignOwnerUidIfNoWorkouts({
    required String expectedOwnerUid,
    required String newUid,
  }) async {
    reassignOwnerIfNoWorkoutsCallCount++;
    if (hasWorkoutProgressValue) {
      throw StateError('Local workout progress exists.');
    }
    await reassignOwnerUid(expectedOwnerUid: expectedOwnerUid, newUid: newUid);
  }

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
  Future<void> importSnapshot(
    BackupSnapshot snapshot, {
    required String ownerUid,
  }) async {
    importCallCount++;
    lastImportedSnapshot = snapshot;
    lastImportedOwnerUid = ownerUid;

    final pendingFuture = importFuture;
    if (pendingFuture != null) {
      await pendingFuture;
    }

    final exception = importException;
    if (exception != null) {
      throw exception;
    }

    this.ownerUid = ownerUid;
  }
}

final class FakeCloudBackupRepository implements CloudBackupRepository {
  FakeCloudBackupRepository({
    this.metadataResult,
    this.metadataException,
    this.metadataFuture,
    this.uploadResult,
    this.uploadException,
    this.uploadFuture,
    this.downloadResult,
    this.downloadException,
    this.downloadFuture,
  });

  final CloudBackupMetadata? metadataResult;
  final Object? metadataException;
  final Future<CloudBackupMetadata?>? metadataFuture;
  final CloudBackupMetadata? uploadResult;
  final Object? uploadException;
  final Future<CloudBackupMetadata>? uploadFuture;
  final BackupSnapshot? downloadResult;
  final Object? downloadException;
  final Future<BackupSnapshot?>? downloadFuture;

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

    if (metadataFuture != null) return metadataFuture;

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

    final pendingFuture = downloadFuture;
    if (pendingFuture != null) {
      return pendingFuture;
    }

    final exception = downloadException;
    if (exception != null) {
      throw exception;
    }

    return downloadResult;
  }
}
