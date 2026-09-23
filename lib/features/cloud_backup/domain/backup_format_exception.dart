enum BackupFormatErrorCode {
  malformedJson,
  missingField,
  invalidType,
  invalidValue,
  unsupportedVersion,
  duplicateId,
  invalidReference,
  invalidArchive,
}

final class BackupFormatException implements Exception {
  const BackupFormatException({
    required this.code,
    required this.path,
    required this.message,
    this.cause,
  });

  final BackupFormatErrorCode code;
  final String path;

  //for debug purposes
  final String message;

  //original error, if exception is wrapped in other error
  final Object? cause;

  @override
  String toString() {
    return 'BackupFormatException('
        '${code.name}) at $path: $message';
  }
}

//============================

//============================

// BackupFormatErrorCode.missingField
// // Lipsește cheia "name".

// BackupFormatErrorCode.invalidType
// // "id" este String în loc de int.

// BackupFormatErrorCode.invalidValue
// // is_active este 3 în loc de 0 sau 1.

// BackupFormatErrorCode.duplicateId
// // Două planuri au același id.

// BackupFormatErrorCode.invalidReference
// // split_days.split_id indică un plan inexistent.

// BackupFormatErrorCode.unsupportedVersion
// // Snapshot-ul are formatVersion 2, iar aplicația știe doar v1.

//============================

//============================

//path trebuie primit de DTO, deoarece indexul rândului este cunoscut de clasa care parcurge lista:
// factory SplitPlanBackupRecord.fromDatabaseRow(
//   Map<String, Object?> row, {
//   required String path,
// }) {
//   final id = row['id'];

//   if (id is! int) {
//     throw BackupFormatException(
//       code: BackupFormatErrorCode.invalidType,
//       path: '$path.id',
//       message: 'Expected an integer, received ${id.runtimeType}.',
//     );
//   }

//   // ...
// }

//============================

//============================

// Apelul arată astfel:
// final splitPlans = <SplitPlanBackupRecord>[];

// for (var index = 0; index < rows.length; index++) {
//   splitPlans.add(
//     SplitPlanBackupRecord.fromDatabaseRow(
//       rows[index],
//       path: r'$.data.split_plans' '[$index]',
//     ),
//   );
// }
