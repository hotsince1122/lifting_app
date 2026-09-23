import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_gzip_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_encoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/firebase_storage_error_mapper.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot_validator.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_limits.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_repository.dart';

final class FirebaseCloudBackupRepository implements CloudBackupRepository {
  const FirebaseCloudBackupRepository(this._storage);

  final FirebaseStorage _storage;

  Reference _backupReference(String userId) {
    return _storage.ref('users/$userId/backups/latest.json.gz');
  }

  @override
  Future<CloudBackupMetadata> uploadBackup({
    required String userId,
    required BackupSnapshot snapshot,
  }) async {
    validateBackupSnapshot(snapshot);

    final jsonBytes = Uint8List.fromList(encodeBackupSnapshotBytes(snapshot));

    if (jsonBytes.length > maxUncompressedBackupBytes) {
      throw CloudBackupException(CloudBackupErrorCode.sizeLimitExceeded);
    }

    final compressedBytes = Uint8List.fromList(gzip.encode(jsonBytes));

    if (compressedBytes.length > maxCompressedBackupBytes) {
      throw const CloudBackupException(CloudBackupErrorCode.sizeLimitExceeded);
    }

    try {
      final result = await _backupReference(userId).putData(
        compressedBytes,
        SettableMetadata(contentType: 'application/gzip'),
      );

      final metadata = result.metadata;
      if (metadata == null) {
        throw const CloudBackupException(CloudBackupErrorCode.unknown);
      }

      return _mapMetadata(metadata);
    } on FirebaseException catch (exception) {
      throw mapFirebaseStorageException(exception);
    }
  }

  @override
  Future<BackupSnapshot?> downloadBackup({required String userId}) async {
    final Uint8List? compressedBytes;

    try {
      compressedBytes = await _backupReference(
        userId,
      ).getData(maxCompressedBackupBytes);
    } on FirebaseException catch (exception) {
      if (exception.code == 'object-not-found') {
        return null;
      }

      throw mapFirebaseStorageException(exception);
    }

    if (compressedBytes == null) {
      throw const CloudBackupException(CloudBackupErrorCode.unknown);
    }

    late final String json;

    try {
      final jsonBytes = decompressBackupBytes(
        compressedBytes,
        maxOutputBytes: maxUncompressedBackupBytes,
      );

      json = utf8.decode(jsonBytes);
    } on FormatException catch (error) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidArchive,
        path: r'$',
        message: 'The backup is not a valid gzip archive or UTF-8 document.',
        cause: error,
      );
    }

    final snapshot = decodeBackupSnapshot(json);
    validateBackupSnapshot(snapshot);

    return snapshot;
  }

  @override
  Future<CloudBackupMetadata?> getBackupMetadata({
    required String userId,
  }) async {
    try {
      final metadata = await _backupReference(userId).getMetadata();

      return _mapMetadata(metadata);
    } on FirebaseException catch (exception) {
      if (exception.code == 'object-not-found') {
        return null;
      }

      throw mapFirebaseStorageException(exception);
    }
  }

  CloudBackupMetadata _mapMetadata(FullMetadata metadata) {
    final uploadedAt = metadata.timeCreated;

    if (uploadedAt == null) {
      throw CloudBackupException(CloudBackupErrorCode.unknown);
    }

    final sizeBytes = metadata.size;

    if (sizeBytes == null || sizeBytes < 0) {
      throw CloudBackupException(CloudBackupErrorCode.unknown);
    }

    return CloudBackupMetadata(
      uploadedAt: uploadedAt.toUtc(),
      sizeBytes: sizeBytes,
    );
  }
}
