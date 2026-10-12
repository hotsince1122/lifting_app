import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/sqlite_local_backup_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('SQLite repository forwards local ownership and progress', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifting_tracker_owner_test_',
    );
    await databaseFactory.setDatabasesPath(temporaryDirectory.path);
    final database = await AppDatabase.getDatabase();
    const repository = SqliteLocalBackupRepository();

    try {
      // Arrange: a fresh database has no owner.
      expect(await repository.loadOwnerUid(), isNull);

      // Act and assert: an empty UID cannot claim the data.
      await expectLater(repository.claimForUid('  '), throwsArgumentError);
      expect(await repository.loadOwnerUid(), isNull);

      // The first UID claims the data; the same claim is idempotent.
      await repository.claimForUid('user-a');
      expect(await repository.loadOwnerUid(), 'user-a');
      await repository.claimForUid('user-a');
      expect(await repository.loadOwnerUid(), 'user-a');

      // A second account cannot take ownership or change the stored UID.
      await expectLater(repository.claimForUid('user-b'), throwsStateError);
      expect(await repository.loadOwnerUid(), 'user-a');

      expect(await repository.hasWorkoutProgress(), isFalse);
      await database.insert('workout_sessions', {
        'workout_name': 'Started workout',
        'started_at': 1,
        'status': 'active',
      });
      expect(await repository.hasWorkoutProgress(), isTrue);

      await repository.reassignOwnerUid(
        expectedOwnerUid: 'user-a',
        newUid: 'user-b',
      );
      expect(await repository.loadOwnerUid(), 'user-b');
      await expectLater(
        repository.reassignOwnerUid(
          expectedOwnerUid: 'user-a',
          newUid: 'user-c',
        ),
        throwsStateError,
      );
      expect(await repository.loadOwnerUid(), 'user-b');
    } finally {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
