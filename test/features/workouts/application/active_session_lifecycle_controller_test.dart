import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';
import 'package:lifting_tracker_app/features/progress/domain/weekly_workout_progress.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'finishes the workout while automatic backup is still waiting',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'lifting_tracker_workout_backup_test_',
      );
      await databaseFactory.setDatabasesPath(temporaryDirectory.path);
      final database = await AppDatabase.getDatabase();
      final backup = _WaitingBackupController();
      final container = ProviderContainer.test(
        overrides: [
          cloudBackupControllerProvider.overrideWith(() => backup),
          weeklyWorkoutProgressProvider.overrideWith(_LocalWeeklyProgress.new),
        ],
      );

      try {
        final sessionId = await database.insert('workout_sessions', {
          'workout_name': 'Finished workout',
          'started_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'status': 'active',
        });
        await container.read(activeSessionLifecycleProvider.future);

        await container
            .read(activeSessionLifecycleProvider.notifier)
            .endSession(sessionId)
            .timeout(const Duration(seconds: 2));

        expect(container.read(activeSessionLifecycleProvider).value, isFalse);
        await backup.started.future.timeout(const Duration(seconds: 2));
        expect(backup.finished, isFalse);
        final rows = await database.query(
          'workout_sessions',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        expect(rows.single['status'], 'completed');
      } finally {
        backup.release.complete();
        container.dispose();
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}

class _WaitingBackupController extends CloudBackupController {
  final started = Completer<void>();
  final release = Completer<void>();
  bool finished = false;

  @override
  Future<CloudBackupMetadata?> build() async => null;

  @override
  Future<void> backupAutomatically() async {
    started.complete();
    await release.future;
    finished = true;
  }
}

class _LocalWeeklyProgress extends WeeklyWorkoutProgressController {
  @override
  FutureOr<WeeklyWorkoutProgress> build() =>
      WeeklyWorkoutProgress(4, List<bool>.filled(7, false));

  @override
  Future<void> updateProgress(int day) async {}
}
