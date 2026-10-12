import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_queries.dart';

Future<void> claimLocalDataForUid(String uid) async {
  if (uid.trim().isEmpty) {
    throw ArgumentError('Uid cannot be an empty string');
  }

  final db = await AppDatabase.getDatabase();

  final updatedRows = await db.rawUpdate(
    '''
      UPDATE app_settings
      SET local_data_owner_uid = ?
      WHERE id = 1 AND local_data_owner_uid IS NULL
      ''',
    [uid],
  );

  if (updatedRows == 1) return;

  final currentOwner = await loadLocalDataOwnerUid();
  if (currentOwner == uid) return;

  throw StateError('Local data belongs to another account.');
}

Future<void> reassignLocalDataOwnerUid({
  required String expectedOwnerUid,
  required String newUid,
}) async {
  if (expectedOwnerUid.trim().isEmpty || newUid.trim().isEmpty) {
    throw ArgumentError('Uids cannot be empty strings.');
  }

  if (expectedOwnerUid.trim() == newUid.trim()) {
    throw ArgumentError('Uids cannot be the same.');
  }

  final db = await AppDatabase.getDatabase();

  final updatedRows = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET local_data_owner_uid = ?
    WHERE id = 1 AND local_data_owner_uid = ?
    ''',
    [newUid, expectedOwnerUid],
  );

  if (updatedRows == 1) return;

  throw StateError('Local data owner does not match the expected UID.');
}

Future<void> reassignLocalDataOwnerUidIfNoWorkouts({
  required String expectedOwnerUid,
  required String newUid,
}) async {
  if (expectedOwnerUid.trim().isEmpty || newUid.trim().isEmpty) {
    throw ArgumentError('Uids cannot be empty strings.');
  }

  if (expectedOwnerUid.trim() == newUid.trim()) {
    throw ArgumentError('Uids cannot be the same.');
  }

  final db = await AppDatabase.getDatabase();
  final updatedRows = await db.rawUpdate(
    '''
    UPDATE app_settings
    SET local_data_owner_uid = ?
    WHERE id = 1
      AND local_data_owner_uid = ?
      AND NOT EXISTS (SELECT 1 FROM workout_sessions)
    ''',
    [newUid, expectedOwnerUid],
  );

  if (updatedRows == 1) return;

  throw StateError('Local data owner changed or workout progress was created.');
}
