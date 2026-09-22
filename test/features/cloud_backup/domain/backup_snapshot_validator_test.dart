import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot_validator.dart';

import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  group('validateBackupSnapshot', () {
    test('accepts a valid snapshot', () {
      final snapshot = buildBackupSnapshotFixture();

      expect(() => validateBackupSnapshot(snapshot), returnsNormally);
    });

    test('rejects an app settings id different from 1', () {
      final snapshot = _snapshotWithDataMutation((data) {
        final appSettings = data['app_settings']! as Map<String, Object?>;
        appSettings['id'] = 2;
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidValue,
          path: r'$.data.app_settings.id',
        ),
      );
    });

    test('rejects a duplicate table id', () {
      final snapshot = _snapshotWithDataMutation((data) {
        final rows = data['split_plans']! as List<Object?>;
        rows.add(Map<String, Object>.from(rows.first! as Map<String, Object>));
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.duplicateId,
          path: r'$.data.split_plans[1].id',
        ),
      );
    });

    test('rejects a split day that references a missing split plan', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'split_days')['split_id'] = 999;
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.split_days[0].split_id',
        ),
      );
    });

    test('rejects a day exercise that references a missing split day', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'day_exercises')['day_id'] = 'missing-day';
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.day_exercises[0].day_id',
        ),
      );
    });

    test('rejects a day exercise that references a missing exercise', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'day_exercises')['exercise_id'] = 'missing-exercise';
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.day_exercises[0].exercise_id',
        ),
      );
    });

    test('accepts a workout session without a split day', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _rowAt(data, 'workout_sessions', 1)['day_id'] = null;
      });

      expect(() => validateBackupSnapshot(snapshot), returnsNormally);
    });

    test('rejects a workout session that references a missing split day', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'workout_sessions')['day_id'] = 'missing-day';
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.workout_sessions[0].day_id',
        ),
      );
    });

    test('rejects a logged set that references a missing session', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'logged_sets')['session_id'] = 999;
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.logged_sets[0].session_id',
        ),
      );
    });

    test('rejects a logged set that references a missing exercise', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'logged_sets')['ex_id'] = 'missing-exercise';
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.logged_sets[0].ex_id',
        ),
      );
    });

    test('rejects an active set that references a missing session', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'active_session_sets')['workout_session_id'] = 999;
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.active_session_sets[0].workout_session_id',
        ),
      );
    });

    test('rejects an active set that references a missing exercise', () {
      final snapshot = _snapshotWithDataMutation((data) {
        _firstRow(data, 'active_session_sets')['exercise_id'] =
            'missing-exercise';
      });

      expect(
        () => validateBackupSnapshot(snapshot),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidReference,
          path: r'$.data.active_session_sets[0].exercise_id',
        ),
      );
    });
  });
}

BackupSnapshot _snapshotWithDataMutation(
  void Function(Map<String, Object?> data) mutate,
) {
  final json = buildBackupSnapshotJsonFixture();
  final data = json['data']! as Map<String, Object?>;
  mutate(data);
  return decodeBackupSnapshot(jsonEncode(json));
}

Map<String, Object?> _firstRow(Map<String, Object?> data, String tableName) {
  return _rowAt(data, tableName, 0);
}

Map<String, Object?> _rowAt(
  Map<String, Object?> data,
  String tableName,
  int index,
) {
  final rows = data[tableName]! as List<Object?>;
  return rows[index]! as Map<String, Object?>;
}

Matcher _throwsBackupFormatException({
  required BackupFormatErrorCode code,
  required String path,
}) {
  return throwsA(
    isA<BackupFormatException>()
        .having((exception) => exception.code, 'code', code)
        .having((exception) => exception.path, 'path', path),
  );
}
