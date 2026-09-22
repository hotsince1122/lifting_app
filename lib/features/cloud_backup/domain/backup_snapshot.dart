import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class BackupSnapshot {
  const BackupSnapshot({
    required this.backupFormatVersion,
    required this.createdAt,
    required this.data,
  });

  static const currentFormatVersion = 1;

  final int backupFormatVersion;
  final DateTime createdAt;
  final BackupData data;

  Map<String, Object?> toJson() {
    return {
      'backupFormatVersion': backupFormatVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'data': data.toJson(),
    };
  }

  factory BackupSnapshot.fromJson(Map<String, Object?> json, String path) {
    final reader = BackupRecordReader(json, path: path);

    final backupFormatVersion = reader.requiredInt('backupFormatVersion');
    if (backupFormatVersion != currentFormatVersion) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.unsupportedVersion,
        path: '$path.backupFormatVersion',
        message: 'Backup version is not compatible with current app version',
      );
    }

    final createdAt = DateTime.tryParse(reader.requiredString('createdAt'));
    if (createdAt == null) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidValue,
        path: '$path.createdAt',
        message: 'Date of createdAt field is invalid.',
      );
    }

    final dataJson = reader.requiredMap('data');

    return BackupSnapshot(
      backupFormatVersion: backupFormatVersion,
      createdAt: createdAt,
      data: BackupData.fromJson(dataJson, '$path.data'),
    );
  }
}
