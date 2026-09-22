import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/app_settings_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/day_exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/logged_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_days_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/workout_sessions_backup_record.dart';

void main() {
  group('table backup records', () {
    _databaseRowMappingTest(
      tableName: 'split_plans',
      row: {'id': 7, 'name': 'Push Pull Legs', 'is_preset': 1, 'is_active': 1},
      convert: (row, path) =>
          SplitPlansBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'split_days',
      row: {'id': 'pull-day', 'split_id': 7, 'name': 'Pull', 'order_idx': 2},
      convert: (row, path) =>
          SplitDaysBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'exercises',
      row: {
        'id': 'bicep_curls',
        'name': 'Bicep Curls',
        'muscle_group': 'biceps',
      },
      convert: (row, path) =>
          ExercisesBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'day_exercises',
      row: {
        'id': 15,
        'day_id': 'pull-day',
        'exercise_id': 'bicep_curls',
        'order_idx': null,
      },
      convert: (row, path) =>
          DayExercisesBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'workout_sessions',
      row: {
        'id': 21,
        'workout_name': 'Pull',
        'day_id': 'pull-day',
        'started_at': 1770000000000,
        'finished_at': null,
        'duration_seconds': null,
        'cycle_index': 3,
        'status': 'active',
      },
      convert: (row, path) =>
          WorkoutSessionsBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'logged_sets',
      row: {
        'id': 32,
        'ex_id': 'bicep_curls',
        'session_id': 21,
        'weight': 14.5,
        'repetitions': 10,
        'notes': null,
        'set_index': 2,
        'is_warmup': 0,
        'order_index': 4,
        'exercise_occurrence_index': 1,
      },
      convert: (row, path) =>
          LoggedSetsBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'active_session_sets',
      row: {
        'id': 41,
        'workout_session_id': 21,
        'exercise_id': 'bicep_curls',
        'exercise_order_index': 4,
        'exercise_occurrence_index': 1,
        'set_index': 2,
        'hint_weight': 14.5,
        'hint_repetitions': 10,
        'hint_notes': 'Controlled eccentric',
        'actual_weight': null,
        'actual_repetitions': null,
        'actual_notes': null,
        'is_warmup': 0,
      },
      convert: (row, path) =>
          ActiveSessionSetsBackupRecord.fromDatabaseRow(row, path).toJson(),
    );

    _databaseRowMappingTest(
      tableName: 'app_settings',
      row: {
        'id': 1,
        'week_streak': 8,
        'workouts_per_week_target': 4,
        'weekly_gym_attendance': '1101100',
        'weekly_gym_attendance_week_start': '2026-09-07',
        'did_user_finish_setup': 1,
      },
      convert: (row, path) =>
          AppSettingsBackupRecord.fromDatabaseRow(row, path).toJson(),
    );
  });
}

void _databaseRowMappingTest({
  required String tableName,
  required Map<String, Object?> row,
  required Map<String, Object?> Function(Map<String, Object?> row, String path)
  convert,
}) {
  test('maps a row from $tableName to snapshot JSON', () {
    final json = convert(
      row,
      r'$.data.'
      '$tableName[0]',
    );

    expect(json, row);
  });
}
