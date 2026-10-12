import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/local_data_owner_queries.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('ignores seeded presets and detects a started workout', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifting_tracker_progress_test_',
    );
    await databaseFactory.setDatabasesPath(temporaryDirectory.path);
    final database = await AppDatabase.getDatabase();

    try {
      expect(await hasLocalWorkoutProgress(), isFalse);

      await database.insert('workout_sessions', {
        'workout_name': 'Started workout',
        'started_at': 1,
        'status': 'active',
      });

      expect(await hasLocalWorkoutProgress(), isTrue);
    } finally {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
