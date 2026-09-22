import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';

final class BackupRecordReader {
  const BackupRecordReader(this.values, {required this.path});

  final Map<String, Object?> values;
  final String path;

  int requiredInt(String key) {
    return _required<int>(key, expectedType: 'an integer');
  }

  int? nullableInt(String key) {
    return _nullable<int>(key, expectedType: 'an integer or null');
  }

  String requiredString(String key) {
    return _required<String>(key, expectedType: 'a string');
  }

  String? nullableString(String key) {
    return _nullable<String>(key, expectedType: 'a string or null');
  }

  double requiredDouble(String key) {
    final value = _required<num>(key, expectedType: 'a number');
    return value.toDouble();
  }

  double? nullableDouble(String key) {
    final value = _nullable<num>(key, expectedType: 'a number or null');

    return value?.toDouble();
  }

  int requiredSqlBoolean(String key) {
    final value = requiredInt(key);

    if (value != 0 && value != 1) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidValue,
        path: '$path.$key',
        message: 'Expected 0 or 1.',
      );
    }

    return value;
  }

  List<Object?> requiredList(String key) {
    final value = _required<List<Object?>>(key, expectedType: 'a list');
    return value;
  }

  Map<String, Object?> requiredMap(String key) {
    final value = _required<Map<String, Object?>>(
      key,
      expectedType: 'an object',
    );
    return value;
  }

  T _required<T>(String key, {required String expectedType}) {
    if (!values.containsKey(key)) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.missingField,
        path: '$path.$key',
        message: 'Required field is missing.',
      );
    }

    final value = values[key];

    if (value is! T) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidType,
        path: '$path.$key',
        message: 'Expected $expectedType, received ${value.runtimeType}.',
      );
    }

    return value;
  }

  T? _nullable<T>(String key, {required String expectedType}) {
    if (!values.containsKey(key)) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.missingField,
        path: '$path.$key',
        message: 'Required nullable field is missing.',
      );
    }

    final value = values[key];

    if (value == null) return null;

    if (value is! T) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidType,
        path: '$path.$key',
        message: 'Expected $expectedType, received ${value.runtimeType}.',
      );
    }

    return value as T?;
  }
}
