import 'dart:convert';

import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';

String encodeBackupSnapshot(BackupSnapshot snapshot) {
  return jsonEncode(snapshot.toJson());
}

List<int> encodeBackupSnapshotBytes(BackupSnapshot snapshot) {
  return utf8.encode(encodeBackupSnapshot(snapshot));
}