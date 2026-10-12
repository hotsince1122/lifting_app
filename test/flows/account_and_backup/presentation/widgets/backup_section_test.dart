import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/is_automatic_backup_enabled_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/features/history/application/completed_workouts_count_provider.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/widgets/backup_section.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/widgets/progress_protection_notice.dart';

import '../../../../features/authentication/test_doubles/fake_auth_repository.dart';
import '../../../../features/cloud_backup/test_doubles/fake_backup_repositories.dart';
import '../../../../features/cloud_backup/test_fixtures/backup_snapshot_fixture.dart';

class _PendingBackupController extends CloudBackupController {
  final pending = Completer<CloudBackupMetadata?>();

  @override
  Future<CloudBackupMetadata?> build() => pending.future;
}

class _AutomaticBackupSetting extends IsAutomaticBackupEnabledController {
  @override
  FutureOr<bool> build() => false;
}

void main() {
  testWidgets('asks before restore and reports success after confirmation', (
    tester,
  ) async {
    var workoutCount = 1;
    final snapshot = buildBackupSnapshotFixture();
    final cloud = FakeCloudBackupRepository(
      metadataResult: CloudBackupMetadata(
        uploadedAt: DateTime.utc(2026, 9, 23, 10),
        sizeBytes: 1024,
      ),
      downloadResult: snapshot,
    );
    final local = FakeLocalBackupRepository(
      snapshot: snapshot,
      ownerUid: 'user-b',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(authState: Stream.value(_user('user-a'))),
          ),
          cloudBackupRepositoryProvider.overrideWithValue(cloud),
          localBackupRepositoryProvider.overrideWithValue(local),
          lastBackupDateRepositoryProvider.overrideWithValue(
            FakeLastBackupDateRepository(),
          ),
          isAutomaticBackupEnabledController.overrideWith(
            _AutomaticBackupSetting.new,
          ),
          completedWorkoutCountProvider.overrideWith(
            (ref) async => workoutCount,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [ProgressProtectionNotice(), BackupSection()],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore from cloud backup'));
    await tester.pumpAndSettle();
    expect(find.text('Replace data on this device ?'), findsOneWidget);
    expect(cloud.downloadCallCount, 0);

    await tester.tap(find.text('Keep local data'));
    await tester.pumpAndSettle();
    expect(local.importCallCount, 0);
    expect(local.ownerUid, 'user-b');
    workoutCount = 3;

    await tester.tap(find.text('Restore from cloud backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore backup'));
    await tester.pumpAndSettle();

    expect(cloud.lastDownloadUserId, 'user-a');
    expect(local.importCallCount, 1);
    expect(local.ownerUid, 'user-a');
    expect(find.text('Backup restored'), findsOneWidget);
    expect(find.text('3 workouts'), findsOneWidget);
  });

  testWidgets('shows the UID-scoped cached date while cloud is still loading', (
    tester,
  ) async {
    final cache = FakeLastBackupDateRepository()
      ..dates['user-a'] = DateTime.utc(2026, 9, 23, 10);
    final controller = _PendingBackupController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(authState: Stream.value(_user('user-a'))),
          ),
          cloudBackupControllerProvider.overrideWith(() => controller),
          lastBackupDateRepositoryProvider.overrideWithValue(cache),
          isAutomaticBackupEnabledController.overrideWith(
            _AutomaticBackupSetting.new,
          ),
          completedWorkoutCountProvider.overrideWith((ref) async => 1),
        ],
        child: const MaterialApp(home: Scaffold(body: BackupSection())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Last known backup:'), findsOneWidget);
    expect(find.text('Working on cloud backup…'), findsNothing);

    controller.pending.completeError(StateError('Offline'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Last known backup:'), findsOneWidget);
  });

  testWidgets('never shows another UID’s cached date', (tester) async {
    final cache = FakeLastBackupDateRepository()
      ..dates['user-a'] = DateTime.utc(2026, 9, 23, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(authState: Stream.value(_user('user-b'))),
          ),
          cloudBackupControllerProvider.overrideWith(
            _PendingBackupController.new,
          ),
          lastBackupDateRepositoryProvider.overrideWithValue(cache),
          isAutomaticBackupEnabledController.overrideWith(
            _AutomaticBackupSetting.new,
          ),
          completedWorkoutCountProvider.overrideWith((ref) async => 1),
        ],
        child: const MaterialApp(home: Scaffold(body: BackupSection())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Last known backup:'), findsNothing);
    expect(find.text('Working on cloud backup…'), findsOneWidget);
  });

  testWidgets('shows the backup notice after metadata times out offline', (
    tester,
  ) async {
    final cache = FakeLastBackupDateRepository()
      ..dates['user-a'] = DateTime.utc(2026, 9, 23, 10);
    final pendingMetadata = Completer<CloudBackupMetadata?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(authState: Stream.value(_user('user-a'))),
          ),
          cloudBackupRepositoryProvider.overrideWithValue(
            FakeCloudBackupRepository(metadataFuture: pendingMetadata.future),
          ),
          lastBackupDateRepositoryProvider.overrideWithValue(cache),
          isAutomaticBackupEnabledController.overrideWith(
            _AutomaticBackupSetting.new,
          ),
          completedWorkoutCountProvider.overrideWith((ref) async => 1),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [ProgressProtectionNotice(), BackupSection()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Checking cloud…'), findsOneWidget);

    await tester.tap(find.text('Back up now'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(find.text('Cloud backup request timed out'), findsOneWidget);
    expect(find.textContaining('Last known backup:'), findsOneWidget);
  });
}

AuthUser _user(String id) => AuthUser(
  id: id,
  email: 'user@example.com',
  isEmailVerified: true,
  providers: const {AuthProviderType.emailPassword},
);
