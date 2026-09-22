import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class WorkoutSessionsBackupRecord {
  const WorkoutSessionsBackupRecord({
    required this.id,
    required this.workoutName,
    required this.dayId,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.cycleIndex,
    required this.status,
  });

  final int id;
  final String workoutName;
  final String? dayId;
  final int startedAt;
  final int? finishedAt;
  final int? durationSeconds;
  final int? cycleIndex;
  final String status;

  factory WorkoutSessionsBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return WorkoutSessionsBackupRecord(
      id: reader.requiredInt('id'),
      workoutName: reader.requiredString('workout_name'),
      dayId: reader.nullableString('day_id'),
      startedAt: reader.requiredInt('started_at'),
      finishedAt: reader.nullableInt('finished_at'),
      durationSeconds: reader.nullableInt('duration_seconds'),
      cycleIndex: reader.nullableInt('cycle_index'),
      status: reader.requiredString('status'),
    );
  }

  factory WorkoutSessionsBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return WorkoutSessionsBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'workout_name': workoutName,
      'day_id': dayId,
      'started_at': startedAt,
      'finished_at' : finishedAt,
      'duration_seconds' : durationSeconds,
      'cycle_index' : cycleIndex,
      'status' : status,
    };
  }
}
