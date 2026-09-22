import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class ExercisesBackupRecord {
  const ExercisesBackupRecord({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });

  final String id;
  final String name;
  final String muscleGroup;

  factory ExercisesBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return ExercisesBackupRecord(
      id: reader.requiredString('id'),
      name: reader.requiredString('name'),
      muscleGroup: reader.requiredString('muscle_group'),
    );
  }

  factory ExercisesBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return ExercisesBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
    };
  }
}
