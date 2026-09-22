import 'dart:convert';

import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';

BackupSnapshot decodeBackupSnapshot(String source) {
  late final Object? decoded;

  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw BackupFormatException(
      code: BackupFormatErrorCode.malformedJson,
      path: r'$',
      message: 'The backup is not valid JSON.',
      cause: error,
    );
  }

  if (decoded is! Map<String, Object?>) {
    throw const BackupFormatException(
      code: BackupFormatErrorCode.invalidType,
      path: r'$',
      message: 'Expected the backup root to be an object.',
    );
  }

  return BackupSnapshot.fromJson(decoded, r'$');
}
