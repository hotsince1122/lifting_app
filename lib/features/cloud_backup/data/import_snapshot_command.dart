import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot_validator.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/app_settings_backup_record.dart';
import 'package:sqflite/sqflite.dart';

Future<void> importSnapshot(BackupSnapshot snapshot) async {
  validateBackupSnapshot(snapshot);

  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await _deleteBackupTables(txn);

    await _writeDatabase(txn, snapshot.data);

    await _updateAppSettingsTable(txn, snapshot.data.appSettings);
  });
}

Future<void> _deleteBackupTables(DatabaseExecutor txn) async {
  await _deleteTable(txn, 'active_session_sets');
  await _deleteTable(txn, 'logged_sets');
  await _deleteTable(txn, 'day_exercises');
  await _deleteTable(txn, 'workout_sessions');
  await _deleteTable(txn, 'split_days');
  await _deleteTable(txn, 'split_plans');
  await _deleteTable(txn, 'exercises');
}

Future<void> _deleteTable(DatabaseExecutor txn, String tableName) async {
  await txn.rawDelete('''
  DELETE FROM $tableName
  ''');
}

Future<void> _writeDatabase(DatabaseExecutor txn, BackupData data) async {
  final batch = txn.batch();

  _writeTableInBatch(
    batch,
    'split_plans',
    data.splitPlans,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'split_days',
    data.splitDays,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'exercises',
    data.exercises,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'day_exercises',
    data.dayExercises,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'workout_sessions',
    data.workoutSessions,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'logged_sets',
    data.loggedSets,
    (record) => record.toJson(),
  );

  _writeTableInBatch(
    batch,
    'active_session_sets',
    data.activeSessionSets,
    (record) => record.toJson(),
  );

  await batch.commit(noResult: true);
}

void _writeTableInBatch<T>(
  Batch batch,
  String tableName,
  List<T> records,
  Map<String, Object?> Function(T) toJson,
) {
  for (final record in records) {
    batch.insert(tableName, toJson(record));
  }
}

Future<void> _updateAppSettingsTable(
  DatabaseExecutor txn,
  AppSettingsBackupRecord settings,
) async {
  final rowsAffected = await txn.rawUpdate(
    '''
    UPDATE app_settings
    SET week_streak = ?, workouts_per_week_target = ?, weekly_gym_attendance = ?, weekly_gym_attendance_week_start = ?, did_user_finish_setup = ?
    WHERE id = 1
    ''',
    [
      settings.weekStreak,
      settings.workoutsPerWeekTarget,
      settings.weeklyGymAttendance,
      settings.weeklyGymAttendanceWeekStart,
      settings.didUserFinishSetup,
    ],
  );

  if (rowsAffected != 1) {
    throw StateError('Did not update exactly 1 row in app_settings table.');
  }
}
