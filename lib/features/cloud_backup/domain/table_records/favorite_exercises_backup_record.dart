import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class FavoriteExercisesBackupRecord {
  const FavoriteExercisesBackupRecord({required this.exerciseId});

  final String exerciseId;

  factory FavoriteExercisesBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return FavoriteExercisesBackupRecord(
      exerciseId: reader.requiredString('exercise_id'),
    );
  }

  factory FavoriteExercisesBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return FavoriteExercisesBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {'exercise_id': exerciseId};
  }
}
