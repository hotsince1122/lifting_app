import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_encoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/export_snapshot_query.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/import_snapshot_command.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot_validator.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  test('round-trips a snapshot and imports it atomically', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifting_tracker_backup_test_',
    );
    await databaseFactory.setDatabasesPath(temporaryDirectory.path);

    final database = await AppDatabase.getDatabase();

    try {
      final snapshot = buildBackupSnapshotFixture();

      await importSnapshot(snapshot);

      final exportedSnapshot = await exportSnapshot();
      final encodedSnapshot = encodeBackupSnapshot(exportedSnapshot);
      final decodedSnapshot = decodeBackupSnapshot(encodedSnapshot);

      validateBackupSnapshot(decodedSnapshot);
      expect(decodedSnapshot.backupFormatVersion, snapshot.backupFormatVersion);
      expect(decodedSnapshot.data.toJson(), snapshot.data.toJson());

      await database.rawUpdate('UPDATE split_plans SET name = ? WHERE id = ?', [
        'Changed locally',
        snapshot.data.splitPlans.single.id,
      ]);

      await importSnapshot(decodedSnapshot);

      await _expectDatabaseToMatchSnapshot(database, decodedSnapshot);

      final stateBeforeFailedImport = await _readBackupTables(database);
      final invalidSnapshot = _withDuplicateActiveSet(decodedSnapshot);

      await expectLater(
        importSnapshot(invalidSnapshot),
        throwsA(isA<DatabaseException>()),
      );

      expect(await _readBackupTables(database), stateBeforeFailedImport);
    } finally {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}

Future<void> _expectDatabaseToMatchSnapshot(
  Database database,
  BackupSnapshot snapshot,
) async {
  final data = snapshot.data;

  expect(await _readTable(database, 'split_plans'), [
    for (final record in data.splitPlans) record.toJson(),
  ]);
  expect(await _readTable(database, 'split_days'), [
    for (final record in data.splitDays) record.toJson(),
  ]);
  expect(await _readTable(database, 'exercises'), [
    for (final record in data.exercises) record.toJson(),
  ]);
  expect(await _readTable(database, 'day_exercises'), [
    for (final record in data.dayExercises) record.toJson(),
  ]);
  expect(await _readTable(database, 'workout_sessions'), [
    for (final record in data.workoutSessions) record.toJson(),
  ]);
  expect(await _readTable(database, 'logged_sets'), [
    for (final record in data.loggedSets) record.toJson(),
  ]);
  expect(await _readTable(database, 'active_session_sets'), [
    for (final record in data.activeSessionSets) record.toJson(),
  ]);
  expect(
    (await _readTable(database, 'app_settings')).single,
    data.appSettings.toJson(),
  );

  expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
}

Future<Map<String, List<Map<String, Object?>>>> _readBackupTables(
  Database database,
) async {
  const tableNames = [
    'split_plans',
    'split_days',
    'exercises',
    'day_exercises',
    'workout_sessions',
    'logged_sets',
    'active_session_sets',
    'app_settings',
  ];

  return {
    for (final tableName in tableNames)
      tableName: await _readTable(database, tableName),
  };
}

Future<List<Map<String, Object?>>> _readTable(
  Database database,
  String tableName,
) {
  return database.rawQuery('SELECT * FROM $tableName ORDER BY id');
}

BackupSnapshot _withDuplicateActiveSet(BackupSnapshot snapshot) {
  final data = snapshot.data;
  final existingSet = data.activeSessionSets.single;

  final duplicateSet = ActiveSessionSetsBackupRecord(
    id: existingSet.id + 1,
    workoutSessionId: existingSet.workoutSessionId,
    exerciseId: existingSet.exerciseId,
    exerciseOrderIndex: existingSet.exerciseOrderIndex,
    exerciseOccurrenceIndex: existingSet.exerciseOccurrenceIndex,
    setIndex: existingSet.setIndex,
    hintWeight: existingSet.hintWeight,
    hintRepetitions: existingSet.hintRepetitions,
    hintNotes: existingSet.hintNotes,
    actualWeight: existingSet.actualWeight,
    actualRepetitions: existingSet.actualRepetitions,
    actualNotes: existingSet.actualNotes,
    isWarmup: existingSet.isWarmup,
  );

  return BackupSnapshot(
    backupFormatVersion: snapshot.backupFormatVersion,
    createdAt: snapshot.createdAt,
    data: BackupData(
      splitPlans: data.splitPlans,
      splitDays: data.splitDays,
      exercises: data.exercises,
      dayExercises: data.dayExercises,
      workoutSessions: data.workoutSessions,
      loggedSets: data.loggedSets,
      activeSessionSets: [...data.activeSessionSets, duplicateSet],
      appSettings: data.appSettings,
    ),
  );
}
