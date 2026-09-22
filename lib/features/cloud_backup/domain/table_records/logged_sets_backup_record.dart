import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class LoggedSetsBackupRecord {
  const LoggedSetsBackupRecord({
    required this.id,
    required this.exerciseId,
    required this.sessionId,
    required this.weight,
    required this.repetitions,
    required this.notes,
    required this.setIndex,
    required this.isWarmup,
    required this.orderIndex,
    required this.exerciseOccurrenceIndex,
  });

  final int id;
  final String exerciseId;
  final int sessionId;
  final double weight;
  final int repetitions;
  final String? notes;
  final int setIndex;
  final int isWarmup;
  final int orderIndex;
  final int exerciseOccurrenceIndex;

  factory LoggedSetsBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return LoggedSetsBackupRecord(
      id: reader.requiredInt('id'),
      exerciseId: reader.requiredString('ex_id'),
      sessionId: reader.requiredInt('session_id'),
      weight: reader.requiredDouble('weight'),
      repetitions: reader.requiredInt('repetitions'),
      notes: reader.nullableString('notes'),
      setIndex: reader.requiredInt('set_index'),
      isWarmup: reader.requiredSqlBoolean('is_warmup'),
      orderIndex: reader.requiredInt('order_index'),
      exerciseOccurrenceIndex: reader.requiredInt('exercise_occurrence_index'),
    );
  }

  factory LoggedSetsBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return LoggedSetsBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'ex_id': exerciseId,
      'session_id': sessionId,
      'weight': weight,
      'repetitions': repetitions,
      'notes': notes,
      'set_index': setIndex,
      'is_warmup': isWarmup,
      'order_index': orderIndex,
      'exercise_occurrence_index': exerciseOccurrenceIndex,
    };
  }
}
