import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/sqlite_local_backup_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'SQLite repository stores pending and forwards missing row errors',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'lifting_tracker_backup_pending_test_',
      );
      await databaseFactory.setDatabasesPath(temporaryDirectory.path);
      final database = await AppDatabase.getDatabase();
      const repository = SqliteLocalBackupRepository();

      try {
        expect(await repository.loadBackupPending(), isFalse);

        await repository.setBackupPending(true);
        expect(await repository.loadBackupPending(), isTrue);

        // Another backup request still means just one pending backup.
        await repository.setBackupPending(true);
        expect(await repository.loadBackupPending(), isTrue);

        await repository.setBackupPending(false);
        expect(await repository.loadBackupPending(), isFalse);

        // Missing settings must not be mistaken for a successful read or write.
        await database.delete('app_settings', where: 'id = ?', whereArgs: [1]);
        await expectLater(repository.loadBackupPending(), throwsStateError);
        await expectLater(repository.setBackupPending(true), throwsStateError);
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
