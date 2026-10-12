import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_commands.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_queries.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'automatic reassignment requires the expected owner and no workouts',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'lifting_tracker_safe_reassignment_test_',
      );
      await databaseFactory.setDatabasesPath(temporaryDirectory.path);
      final database = await AppDatabase.getDatabase();

      try {
        await expectLater(
          reassignLocalDataOwnerUidIfNoWorkouts(
            expectedOwnerUid: 'user-a',
            newUid: 'user-b',
          ),
          throwsStateError,
        );

        await claimLocalDataForUid('user-a');
        final sessionId = await database.insert('workout_sessions', {
          'workout_name': 'Started workout',
          'started_at': 1,
          'status': 'active',
        });

        await expectLater(
          reassignLocalDataOwnerUidIfNoWorkouts(
            expectedOwnerUid: 'user-a',
            newUid: 'user-b',
          ),
          throwsStateError,
        );
        expect(await loadLocalDataOwnerUid(), 'user-a');

        await database.delete(
          'workout_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        await reassignLocalDataOwnerUidIfNoWorkouts(
          expectedOwnerUid: 'user-a',
          newUid: 'user-b',
        );
        expect(await loadLocalDataOwnerUid(), 'user-b');

        await expectLater(
          reassignLocalDataOwnerUidIfNoWorkouts(
            expectedOwnerUid: 'user-a',
            newUid: 'user-c',
          ),
          throwsStateError,
        );
        expect(await loadLocalDataOwnerUid(), 'user-b');
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
