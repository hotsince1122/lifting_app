import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/app_settings_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/day_exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/logged_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_days_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/workout_sessions_backup_record.dart';

Future<BackupSnapshot> exportSnapshot() async {
  final db = await AppDatabase.getDatabase();

  return db.transaction((txn) async {
    final splitPlansRows = await txn.rawQuery('''
      SELECT id, name, is_preset, is_active
      FROM split_plans
      ORDER BY id
    ''');

    final splitPlans = _readRecords(
      splitPlansRows,
      tableName: 'split_plans',
      fromDatabaseRow: SplitPlansBackupRecord.fromDatabaseRow,
    );

    final splitDaysRows = await txn.rawQuery('''
      SELECT id, split_id, name, order_idx
      FROM split_days
      ORDER BY id
    ''');

    final splitDays = _readRecords(
      splitDaysRows,
      tableName: 'split_days',
      fromDatabaseRow: SplitDaysBackupRecord.fromDatabaseRow,
    );

    final exercisesRows = await txn.rawQuery('''
      SELECT id, name, muscle_group
      FROM exercises
      ORDER BY id
    ''');

    final exercises = _readRecords(
      exercisesRows,
      tableName: 'exercises',
      fromDatabaseRow: ExercisesBackupRecord.fromDatabaseRow,
    );

    final dayExercisesRows = await txn.rawQuery('''
      SELECT id, day_id, exercise_id, order_idx
      FROM day_exercises
      ORDER BY id
    ''');

    final dayExercises = _readRecords(
      dayExercisesRows,
      tableName: 'day_exercises',
      fromDatabaseRow: DayExercisesBackupRecord.fromDatabaseRow,
    );

    final workoutSessionsRows = await txn.rawQuery('''
      SELECT
        id,
        workout_name,
        day_id,
        started_at,
        finished_at,
        duration_seconds,
        cycle_index,
        status
      FROM workout_sessions
      ORDER BY id
    ''');

    final workoutSessions = _readRecords(
      workoutSessionsRows,
      tableName: 'workout_sessions',
      fromDatabaseRow: WorkoutSessionsBackupRecord.fromDatabaseRow,
    );

    final loggedSetsRows = await txn.rawQuery('''
      SELECT
        id,
        ex_id,
        session_id,
        weight,
        repetitions,
        notes,
        set_index,
        is_warmup,
        order_index,
        exercise_occurrence_index
      FROM logged_sets
      ORDER BY id
    ''');

    final loggedSets = _readRecords(
      loggedSetsRows,
      tableName: 'logged_sets',
      fromDatabaseRow: LoggedSetsBackupRecord.fromDatabaseRow,
    );

    final activeSessionSetsRows = await txn.rawQuery('''
      SELECT
        id,
        workout_session_id,
        exercise_id,
        exercise_order_index,
        exercise_occurrence_index,
        set_index,
        hint_weight,
        hint_repetitions,
        hint_notes,
        actual_weight,
        actual_repetitions,
        actual_notes,
        is_warmup
      FROM active_session_sets
      ORDER BY id
    ''');

    final activeSessionSets = _readRecords(
      activeSessionSetsRows,
      tableName: 'active_session_sets',
      fromDatabaseRow: ActiveSessionSetsBackupRecord.fromDatabaseRow,
    );

    final appSettingsRows = await txn.rawQuery('''
      SELECT
        id,
        week_streak,
        workouts_per_week_target,
        weekly_gym_attendance,
        weekly_gym_attendance_week_start,
        did_user_finish_setup
      FROM app_settings
      ORDER BY id
    ''');

    if (appSettingsRows.isEmpty) {
      throw const BackupFormatException(
        code: BackupFormatErrorCode.missingField,
        path: r'$.data.app_settings',
        message: 'The app settings row is missing.',
      );
    }

    if (appSettingsRows.length > 1) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.duplicateId,
        path: r'$.data.app_settings',
        message: 'The app settings table contains more than one row.',
      );
    }

    final appSettings = AppSettingsBackupRecord.fromDatabaseRow(
      appSettingsRows.single,
      r'$.data.app_settings',
    );

    if (appSettings.id != 1) {
      throw const BackupFormatException(
        code: BackupFormatErrorCode.invalidValue,
        path: r'$.data.app_settings.id',
        message: 'The app settings row must have id 1.',
      );
    }

    return BackupSnapshot(
      backupFormatVersion: BackupSnapshot.currentFormatVersion,
      createdAt: DateTime.now().toUtc(),
      data: BackupData(
        splitPlans: splitPlans,
        splitDays: splitDays,
        exercises: exercises,
        dayExercises: dayExercises,
        workoutSessions: workoutSessions,
        loggedSets: loggedSets,
        activeSessionSets: activeSessionSets,
        appSettings: appSettings,
      ),
    );
  });
}

List<T> _readRecords<T>(
  List<Map<String, Object?>> rows, {
  required String tableName,
  required T Function(Map<String, Object?> row, String path) fromDatabaseRow,
}) {
  return [
    for (var index = 0; index < rows.length; index++)
      fromDatabaseRow(
        rows[index],
        r'$.data.'
        '$tableName[$index]',
      ),
  ];
}
