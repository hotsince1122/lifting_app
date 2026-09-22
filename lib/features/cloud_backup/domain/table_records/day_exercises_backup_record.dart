import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class DayExercisesBackupRecord {
  const DayExercisesBackupRecord({
    required this.id,
    required this.dayId,
    required this.exerciseId,
    required this.orderIdx,
  });

  final int id;
  final String dayId;
  final String exerciseId;
  final int? orderIdx;

  factory DayExercisesBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return DayExercisesBackupRecord(
      id: reader.requiredInt('id'),
      dayId: reader.requiredString('day_id'),
      exerciseId: reader.requiredString('exercise_id'),
      orderIdx: reader.nullableInt('order_idx'),
    );
  }

  factory DayExercisesBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return DayExercisesBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'day_id': dayId,
      'exercise_id': exerciseId,
      'order_idx': orderIdx,
    };
  }
}
