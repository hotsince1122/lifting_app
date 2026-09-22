import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

const _field = 'value';
const _path = r'$.data.active_session_sets[0]';

void main() {
  group('BackupRecordReader valid values', () {
    _readsValueTest<int>(
      description: 'requiredInt returns an integer',
      databaseValue: 12,
      expectedValue: 12,
      read: (reader) => reader.requiredInt(_field),
    );

    _readsValueTest<int?>(
      description: 'nullableInt returns an integer',
      databaseValue: 12,
      expectedValue: 12,
      read: (reader) => reader.nullableInt(_field),
    );

    _readsValueTest<int?>(
      description: 'nullableInt returns null',
      databaseValue: null,
      expectedValue: null,
      read: (reader) => reader.nullableInt(_field),
    );

    _readsValueTest<String>(
      description: 'requiredString returns a string',
      databaseValue: 'Bicep Curls',
      expectedValue: 'Bicep Curls',
      read: (reader) => reader.requiredString(_field),
    );

    _readsValueTest<String?>(
      description: 'nullableString returns a string',
      databaseValue: 'Controlled eccentric',
      expectedValue: 'Controlled eccentric',
      read: (reader) => reader.nullableString(_field),
    );

    _readsValueTest<String?>(
      description: 'nullableString returns null',
      databaseValue: null,
      expectedValue: null,
      read: (reader) => reader.nullableString(_field),
    );

    _readsValueTest<double>(
      description: 'requiredDouble converts an integer to a double',
      databaseValue: 100,
      expectedValue: 100.0,
      read: (reader) => reader.requiredDouble(_field),
    );

    _readsValueTest<double?>(
      description: 'nullableDouble returns a double',
      databaseValue: 100.5,
      expectedValue: 100.5,
      read: (reader) => reader.nullableDouble(_field),
    );

    _readsValueTest<double?>(
      description: 'nullableDouble returns null',
      databaseValue: null,
      expectedValue: null,
      read: (reader) => reader.nullableDouble(_field),
    );

    for (final sqlBoolean in [0, 1]) {
      _readsValueTest<int>(
        description: 'requiredSqlBoolean accepts $sqlBoolean',
        databaseValue: sqlBoolean,
        expectedValue: sqlBoolean,
        read: (reader) => reader.requiredSqlBoolean(_field),
      );
    }
  });

  group('BackupRecordReader invalid types', () {
    _invalidTypeTest<int>(
      description: 'requiredInt rejects a string',
      databaseValue: '12',
      read: (reader) => reader.requiredInt(_field),
    );

    _invalidTypeTest<int?>(
      description: 'nullableInt rejects a string',
      databaseValue: '12',
      read: (reader) => reader.nullableInt(_field),
    );

    _invalidTypeTest<String>(
      description: 'requiredString rejects an integer',
      databaseValue: 12,
      read: (reader) => reader.requiredString(_field),
    );

    _invalidTypeTest<String?>(
      description: 'nullableString rejects an integer',
      databaseValue: 12,
      read: (reader) => reader.nullableString(_field),
    );

    _invalidTypeTest<double>(
      description: 'requiredDouble rejects a string',
      databaseValue: '100.5',
      read: (reader) => reader.requiredDouble(_field),
    );

    _invalidTypeTest<double?>(
      description: 'nullableDouble rejects a string',
      databaseValue: '100.5',
      read: (reader) => reader.nullableDouble(_field),
    );

    _invalidTypeTest<int>(
      description: 'requiredSqlBoolean rejects a bool',
      databaseValue: true,
      read: (reader) => reader.requiredSqlBoolean(_field),
    );
  });

  group('BackupRecordReader missing fields', () {
    _missingFieldTest<int>(
      description: 'required fields must be present',
      read: (reader) => reader.requiredInt(_field),
    );

    _missingFieldTest<int?>(
      description: 'nullable fields must still be present',
      read: (reader) => reader.nullableInt(_field),
    );
  });

  group('BackupRecordReader SQL booleans', () {
    for (final invalidValue in [-1, 2]) {
      test('requiredSqlBoolean rejects $invalidValue', () {
        final reader = BackupRecordReader({_field: invalidValue}, path: _path);

        expect(
          () => reader.requiredSqlBoolean(_field),
          _throwsBackupFormatException(BackupFormatErrorCode.invalidValue),
        );
      });
    }
  });
}

void _readsValueTest<T>({
  required String description,
  required Object? databaseValue,
  required T expectedValue,
  required T Function(BackupRecordReader reader) read,
}) {
  test(description, () {
    final reader = BackupRecordReader({_field: databaseValue}, path: _path);

    final actualValue = read(reader);

    expect(actualValue, isA<T>());
    expect(actualValue, expectedValue);
  });
}

void _invalidTypeTest<T>({
  required String description,
  required Object? databaseValue,
  required T Function(BackupRecordReader reader) read,
}) {
  test(description, () {
    final reader = BackupRecordReader({_field: databaseValue}, path: _path);

    expect(
      () => read(reader),
      _throwsBackupFormatException(BackupFormatErrorCode.invalidType),
    );
  });
}

void _missingFieldTest<T>({
  required String description,
  required T Function(BackupRecordReader reader) read,
}) {
  test(description, () {
    const reader = BackupRecordReader({}, path: _path);

    expect(
      () => read(reader),
      _throwsBackupFormatException(BackupFormatErrorCode.missingField),
    );
  });
}

Matcher _throwsBackupFormatException(BackupFormatErrorCode code) {
  return throwsA(
    isA<BackupFormatException>()
        .having((exception) => exception.code, 'code', code)
        .having((exception) => exception.path, 'path', '$_path.$_field'),
  );
}
