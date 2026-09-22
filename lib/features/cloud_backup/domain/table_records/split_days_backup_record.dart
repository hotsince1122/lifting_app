import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class SplitDaysBackupRecord {
  const SplitDaysBackupRecord({
    required this.id,
    required this.splitId,
    required this.name,
    required this.orderIdx,
  });

  final String id;
  final int splitId;
  final String name;
  final int orderIdx;

  factory SplitDaysBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return SplitDaysBackupRecord(
      id: reader.requiredString('id'),
      splitId: reader.requiredInt('split_id'),
      name: reader.requiredString('name'),
      orderIdx: reader.requiredInt('order_idx'),
    );
  }

  factory SplitDaysBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return SplitDaysBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'split_id': splitId, 'name': name, 'order_idx': orderIdx};
  }
}
