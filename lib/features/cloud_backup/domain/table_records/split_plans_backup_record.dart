import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class SplitPlansBackupRecord {
  const SplitPlansBackupRecord({
    required this.id,
    required this.name,
    required this.isPreset,
    required this.isActive,
  });

  final int id;
  final String name;
  final int isPreset;
  final int isActive;

  factory SplitPlansBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return SplitPlansBackupRecord(
      id: reader.requiredInt('id'),
      name: reader.requiredString('name'),
      isPreset: reader.requiredSqlBoolean('is_preset'),
      isActive: reader.requiredSqlBoolean('is_active'),
    );
  }

  factory SplitPlansBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return SplitPlansBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'is_preset': isPreset,
      'is_active': isActive,
    };
  }
}
