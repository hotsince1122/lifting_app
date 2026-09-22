import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class ActiveSessionSetsBackupRecord {
  const ActiveSessionSetsBackupRecord({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.exerciseOrderIndex,
    required this.exerciseOccurrenceIndex,
    required this.setIndex,
    required this.hintWeight,
    required this.hintRepetitions,
    required this.hintNotes,
    required this.actualWeight,
    required this.actualRepetitions,
    required this.actualNotes,
    required this.isWarmup,
  });

  final int id;
  final int workoutSessionId;
  final String exerciseId;
  final int exerciseOrderIndex;
  final int exerciseOccurrenceIndex;
  final int setIndex;
  final double? hintWeight;
  final int? hintRepetitions;
  final String? hintNotes;
  final double? actualWeight;
  final int? actualRepetitions;
  final String? actualNotes;
  final int isWarmup;

  factory ActiveSessionSetsBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return ActiveSessionSetsBackupRecord(
      id: reader.requiredInt('id'),
      workoutSessionId: reader.requiredInt('workout_session_id'),
      exerciseId: reader.requiredString('exercise_id'),
      exerciseOrderIndex: reader.requiredInt('exercise_order_index'),
      exerciseOccurrenceIndex: reader.requiredInt('exercise_occurrence_index'),
      setIndex: reader.requiredInt('set_index'),
      hintWeight: reader.nullableDouble('hint_weight'),
      hintRepetitions: reader.nullableInt('hint_repetitions'),
      hintNotes: reader.nullableString('hint_notes'),
      actualWeight: reader.nullableDouble('actual_weight'),
      actualRepetitions: reader.nullableInt('actual_repetitions'),
      actualNotes: reader.nullableString('actual_notes'),
      isWarmup: reader.requiredSqlBoolean('is_warmup'),
    );
  }

  factory ActiveSessionSetsBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return ActiveSessionSetsBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'workout_session_id': workoutSessionId,
      'exercise_id': exerciseId,
      'exercise_order_index': exerciseOrderIndex,
      'exercise_occurrence_index': exerciseOccurrenceIndex,
      'set_index': setIndex,
      'hint_weight': hintWeight,
      'hint_repetitions': hintRepetitions,
      'hint_notes': hintNotes,
      'actual_weight': actualWeight,
      'actual_repetitions': actualRepetitions,
      'actual_notes': actualNotes,
      'is_warmup': isWarmup,
    };
  }
}
