import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_commands.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_queries.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('reassigns only the expected local owner', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifting_tracker_reassignment_test_',
    );
    await databaseFactory.setDatabasesPath(temporaryDirectory.path);
    final database = await AppDatabase.getDatabase();

    try {
      await expectLater(
        reassignLocalDataOwnerUid(expectedOwnerUid: 'user-a', newUid: 'user-b'),
        throwsStateError,
      );
      expect(await loadLocalDataOwnerUid(), isNull);

      await claimLocalDataForUid('user-a');

      await expectLater(
        reassignLocalDataOwnerUid(
          expectedOwnerUid: 'other-user',
          newUid: 'user-b',
        ),
        throwsStateError,
      );
      expect(await loadLocalDataOwnerUid(), 'user-a');

      await reassignLocalDataOwnerUid(
        expectedOwnerUid: 'user-a',
        newUid: 'user-b',
      );
      expect(await loadLocalDataOwnerUid(), 'user-b');

      await expectLater(
        reassignLocalDataOwnerUid(expectedOwnerUid: 'user-a', newUid: 'user-c'),
        throwsStateError,
      );
      expect(await loadLocalDataOwnerUid(), 'user-b');

      await expectLater(
        reassignLocalDataOwnerUid(expectedOwnerUid: ' ', newUid: 'user-c'),
        throwsArgumentError,
      );
      await expectLater(
        reassignLocalDataOwnerUid(expectedOwnerUid: 'user-b', newUid: ' '),
        throwsArgumentError,
      );
      await expectLater(
        reassignLocalDataOwnerUid(expectedOwnerUid: 'user-b', newUid: 'user-b'),
        throwsArgumentError,
      );
      expect(await loadLocalDataOwnerUid(), 'user-b');
    } finally {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
