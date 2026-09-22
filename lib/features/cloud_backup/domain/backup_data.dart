import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/app_settings_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/day_exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/logged_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_days_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/workout_sessions_backup_record.dart';

final class BackupData {
  const BackupData({
    required this.splitPlans,
    required this.splitDays,
    required this.exercises,
    required this.dayExercises,
    required this.workoutSessions,
    required this.loggedSets,
    required this.activeSessionSets,
    required this.appSettings,
  });

  final List<SplitPlansBackupRecord> splitPlans;
  final List<SplitDaysBackupRecord> splitDays;
  final List<ExercisesBackupRecord> exercises;
  final List<DayExercisesBackupRecord> dayExercises;
  final List<WorkoutSessionsBackupRecord> workoutSessions;
  final List<LoggedSetsBackupRecord> loggedSets;
  final List<ActiveSessionSetsBackupRecord> activeSessionSets;
  final AppSettingsBackupRecord appSettings;

  Map<String, Object?> toJson() {
    return {
      'split_plans': [for (final record in splitPlans) record.toJson()],
      'split_days': [for (final record in splitDays) record.toJson()],
      'exercises': [for (final record in exercises) record.toJson()],
      'day_exercises': [for (final record in dayExercises) record.toJson()],
      'workout_sessions': [
        for (final record in workoutSessions) record.toJson(),
      ],
      'logged_sets': [for (final record in loggedSets) record.toJson()],
      'active_session_sets': [
        for (final record in activeSessionSets) record.toJson(),
      ],
      'app_settings': appSettings.toJson(),
    };
  }

  factory BackupData.fromJson(Map<String, Object?> json, String path) {
    final reader = BackupRecordReader(json, path: path);

    return BackupData(
      splitPlans: _decodedRecordList<SplitPlansBackupRecord>(
        reader.requiredList('split_plans'),
        path: '$path.split_plans',
        decodeRecord: SplitPlansBackupRecord.fromJson,
      ),
      splitDays: _decodedRecordList<SplitDaysBackupRecord>(
        reader.requiredList('split_days'),
        path: '$path.split_days',
        decodeRecord: SplitDaysBackupRecord.fromJson,
      ),
      exercises: _decodedRecordList<ExercisesBackupRecord>(
        reader.requiredList('exercises'),
        path: '$path.exercises',
        decodeRecord: ExercisesBackupRecord.fromJson,
      ),
      dayExercises: _decodedRecordList<DayExercisesBackupRecord>(
        reader.requiredList('day_exercises'),
        path: '$path.day_exercises',
        decodeRecord: DayExercisesBackupRecord.fromJson,
      ),
      workoutSessions: _decodedRecordList<WorkoutSessionsBackupRecord>(
        reader.requiredList('workout_sessions'),
        path: '$path.workout_sessions',
        decodeRecord: WorkoutSessionsBackupRecord.fromJson,
      ),
      loggedSets: _decodedRecordList<LoggedSetsBackupRecord>(
        reader.requiredList('logged_sets'),
        path: '$path.logged_sets',
        decodeRecord: LoggedSetsBackupRecord.fromJson,
      ),
      activeSessionSets: _decodedRecordList<ActiveSessionSetsBackupRecord>(
        reader.requiredList('active_session_sets'),
        path: '$path.active_session_sets',
        decodeRecord: ActiveSessionSetsBackupRecord.fromJson,
      ),
      appSettings: AppSettingsBackupRecord.fromJson(
        reader.requiredMap('app_settings'),
        '$path.app_settings',
      ),
    );
  }
}

typedef BackupRecordDecoder<T> =
    T Function(Map<String, Object?> json, String path);

List<T> _decodedRecordList<T>(
  List<Object?> values, {
  required String path,
  required BackupRecordDecoder<T> decodeRecord,
}) {
  final records = <T>[];

  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    final recordPath = '$path[$index]';

    if (value is! Map<String, Object?>) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidType,
        path: recordPath,
        message: 'Expected an object',
      );
    }

    records.add(decodeRecord(value, recordPath));
  }

  return records;
}
