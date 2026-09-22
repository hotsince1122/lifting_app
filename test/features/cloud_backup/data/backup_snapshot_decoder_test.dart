import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_snapshot_encoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';

import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  group('decodeBackupSnapshot', () {
    test('decodes a complete version 1 snapshot', () {
      final encoded = encodeBackupSnapshot(buildBackupSnapshotFixture());

      final decoded = decodeBackupSnapshot(encoded);

      expect(decoded.toJson(), buildBackupSnapshotJsonFixture());
    });

    test('rejects malformed JSON', () {
      expect(
        () => decodeBackupSnapshot('{invalid json'),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.malformedJson,
          path: r'$',
        ),
      );
    });

    test('rejects a root value that is not an object', () {
      expect(
        () => decodeBackupSnapshot(jsonEncode([1, 2, 3])),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidType,
          path: r'$',
        ),
      );
    });

    test('rejects an unsupported backup format version', () {
      final json = buildBackupSnapshotJsonFixture();
      json['backupFormatVersion'] = 2;

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.unsupportedVersion,
          path: r'$.backupFormatVersion',
        ),
      );
    });

    test('rejects an invalid creation date', () {
      final json = buildBackupSnapshotJsonFixture();
      json['createdAt'] = 'not-a-date';

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidValue,
          path: r'$.createdAt',
        ),
      );
    });

    test('rejects a missing data object', () {
      final json = buildBackupSnapshotJsonFixture()..remove('data');

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.missingField,
          path: r'$.data',
        ),
      );
    });

    test('rejects data when it is not an object', () {
      final json = buildBackupSnapshotJsonFixture();
      json['data'] = <Object?>[];

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidType,
          path: r'$.data',
        ),
      );
    });

    test('rejects a table when it is not a list', () {
      final json = buildBackupSnapshotJsonFixture();
      _dataFrom(json)['split_plans'] = <String, Object?>{};

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidType,
          path: r'$.data.split_plans',
        ),
      );
    });

    test('rejects a table row when it is not an object', () {
      final json = buildBackupSnapshotJsonFixture();
      _dataFrom(json)['split_plans'] = <Object?>[42];

      expect(
        () => decodeBackupSnapshot(jsonEncode(json)),
        _throwsBackupFormatException(
          code: BackupFormatErrorCode.invalidType,
          path: r'$.data.split_plans[0]',
        ),
      );
    });
  });
}

Map<String, Object?> _dataFrom(Map<String, Object?> snapshotJson) {
  return snapshotJson['data']! as Map<String, Object?>;
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