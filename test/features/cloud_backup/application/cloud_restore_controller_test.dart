import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_restore_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/history/application/completed_workouts_count_provider.dart';

import '../../authentication/test_doubles/fake_auth_repository.dart';
import '../test_doubles/fake_backup_repositories.dart';
import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  test('starts without downloading or importing a backup', () async {
    final snapshot = buildBackupSnapshotFixture();
    final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );

    final result = await container.read(cloudRestoreControllerProvider.future);

    expect(result, isNull);
    expect(cloud.downloadCallCount, 0);
    expect(local.importCallCount, 0);
  });

  test('downloads and imports the backup for the signed-in user', () async {
    final user = _buildUser();
    final snapshot = buildBackupSnapshotFixture();
    final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
    final local = FakeLocalBackupRepository(
      snapshot: snapshot,
      ownerUid: 'previous-user',
    );
    final container = _buildContainer(user: user, cloud: cloud, local: local);
    await container.read(cloudRestoreControllerProvider.future);

    await container.read(cloudRestoreControllerProvider.notifier).restoreNow();

    expect(cloud.downloadCallCount, 1);
    expect(cloud.lastDownloadUserId, user.id);
    expect(local.importCallCount, 1);
    expect(local.lastImportedSnapshot, same(snapshot));
    expect(local.lastImportedOwnerUid, user.id);
    expect(local.ownerUid, user.id);
    expect(
      container.read(cloudRestoreControllerProvider).value,
      RestoreResult.restored,
    );
  });

  test(
    'refreshes SQLite-backed providers after a successful restore',
    () async {
      final snapshot = buildBackupSnapshotFixture();
      final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
      final local = FakeLocalBackupRepository(snapshot: snapshot);
      var completedWorkouts = 1;
      final container = ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(authState: Stream.value(_buildUser())),
          ),
          cloudBackupRepositoryProvider.overrideWithValue(cloud),
          localBackupRepositoryProvider.overrideWithValue(local),
          completedWorkoutCountProvider.overrideWith((ref) async {
            return completedWorkouts;
          }),
        ],
      );
      container.listen(authStateProvider, (_, _) {});
      expect(await container.read(completedWorkoutCountProvider.future), 1);

      completedWorkouts = 4;
      await container
          .read(cloudRestoreControllerProvider.notifier)
          .restoreNow();

      expect(await container.read(completedWorkoutCountProvider.future), 4);
    },
  );

  test('reports no backup without changing local data', () async {
    final snapshot = buildBackupSnapshotFixture();
    final cloud = FakeCloudBackupRepository();
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );
    await container.read(cloudRestoreControllerProvider.future);

    await container.read(cloudRestoreControllerProvider.notifier).restoreNow();

    expect(cloud.downloadCallCount, 1);
    expect(local.importCallCount, 0);
    expect(
      container.read(cloudRestoreControllerProvider).value,
      RestoreResult.noBackup,
    );
  });

  testWidgets('clears a completed restore notice after eight seconds', (
    tester,
  ) async {
    final snapshot = buildBackupSnapshotFixture();
    final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );
    await container.read(cloudRestoreControllerProvider.future);

    await container.read(cloudRestoreControllerProvider.notifier).restoreNow();
    expect(
      container.read(cloudRestoreControllerProvider).value,
      RestoreResult.restored,
    );

    await tester.pump(const Duration(seconds: 8));
    expect(container.read(cloudRestoreControllerProvider).value, isNull);
  });

  testWidgets('clears no-backup and error notices after eight seconds', (
    tester,
  ) async {
    final snapshot = buildBackupSnapshotFixture();
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final noBackupContainer = _buildContainer(
      user: _buildUser(),
      cloud: FakeCloudBackupRepository(),
      local: local,
    );
    await noBackupContainer.read(cloudRestoreControllerProvider.future);
    await noBackupContainer
        .read(cloudRestoreControllerProvider.notifier)
        .restoreNow();
    expect(
      noBackupContainer.read(cloudRestoreControllerProvider).value,
      RestoreResult.noBackup,
    );

    await tester.pump(const Duration(seconds: 8));
    expect(
      noBackupContainer.read(cloudRestoreControllerProvider).value,
      isNull,
    );

    final errorContainer = _buildContainer(
      user: _buildUser(),
      cloud: FakeCloudBackupRepository(
        downloadException: StateError('Download failed'),
      ),
      local: local,
    );
    await errorContainer.read(cloudRestoreControllerProvider.future);
    await errorContainer
        .read(cloudRestoreControllerProvider.notifier)
        .restoreNow();
    expect(
      errorContainer.read(cloudRestoreControllerProvider).hasError,
      isTrue,
    );

    await tester.pump(const Duration(seconds: 8));
    final state = errorContainer.read(cloudRestoreControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.value, isNull);
  });

  for (final scenario
      in <({String name, AuthUser? user, CloudBackupErrorCode code})>[
        (name: 'guest', user: null, code: CloudBackupErrorCode.unauthenticated),
        (
          name: 'unverified user',
          user: _buildUser(verified: false),
          code: CloudBackupErrorCode.emailNotVerified,
        ),
      ]) {
    test('rejects ${scenario.name} before download', () async {
      final snapshot = buildBackupSnapshotFixture();
      final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
      final local = FakeLocalBackupRepository(snapshot: snapshot);
      final container = _buildContainer(
        user: scenario.user,
        cloud: cloud,
        local: local,
      );
      await container.read(cloudRestoreControllerProvider.future);

      await container
          .read(cloudRestoreControllerProvider.notifier)
          .restoreNow();

      final error = container.read(cloudRestoreControllerProvider).error;
      expect(error, isA<CloudBackupException>());
      expect((error! as CloudBackupException).code, scenario.code);
      expect(cloud.downloadCallCount, 0);
      expect(local.importCallCount, 0);
    });
  }

  test('keeps local data when downloading fails', () async {
    final snapshot = buildBackupSnapshotFixture();
    const error = CloudBackupException(CloudBackupErrorCode.permissionDenied);
    final cloud = FakeCloudBackupRepository(downloadException: error);
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );
    await container.read(cloudRestoreControllerProvider.future);

    await container.read(cloudRestoreControllerProvider.notifier).restoreNow();

    expect(container.read(cloudRestoreControllerProvider).error, same(error));
    expect(local.importCallCount, 0);
  });

  test('reports an import failure instead of success', () async {
    final snapshot = buildBackupSnapshotFixture();
    final error = StateError('Local import failed');
    final cloud = FakeCloudBackupRepository(downloadResult: snapshot);
    final local = FakeLocalBackupRepository(
      snapshot: snapshot,
      ownerUid: 'previous-user',
      importException: error,
    );
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );
    await container.read(cloudRestoreControllerProvider.future);

    await container.read(cloudRestoreControllerProvider.notifier).restoreNow();

    expect(local.importCallCount, 1);
    expect(local.ownerUid, 'previous-user');
    expect(container.read(cloudRestoreControllerProvider).error, same(error));
  });

  test('ignores a second restore while download is pending', () async {
    final snapshot = buildBackupSnapshotFixture();
    final pendingDownload = Completer<BackupSnapshot?>();
    final cloud = FakeCloudBackupRepository(
      downloadFuture: pendingDownload.future,
    );
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      user: _buildUser(),
      cloud: cloud,
      local: local,
    );
    await container.read(cloudRestoreControllerProvider.future);
    final controller = container.read(cloudRestoreControllerProvider.notifier);

    final firstOperation = controller.restoreNow();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(cloudRestoreControllerProvider).isLoading, isTrue);
    await controller.restoreNow();

    expect(cloud.downloadCallCount, 1);
    expect(local.importCallCount, 0);

    pendingDownload.complete(snapshot);
    await firstOperation;
    expect(local.importCallCount, 1);
    expect(
      container.read(cloudRestoreControllerProvider).value,
      RestoreResult.restored,
    );
  });

  test('does not import when the account changes during download', () async {
    final firstUser = _buildUser();
    final otherUser = _buildUser(id: 'other-user');
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    final snapshot = buildBackupSnapshotFixture();
    final pendingDownload = Completer<BackupSnapshot?>();
    final cloud = FakeCloudBackupRepository(
      downloadFuture: pendingDownload.future,
    );
    final local = FakeLocalBackupRepository(snapshot: snapshot);
    final container = _buildContainer(
      authState: authStream.stream,
      cloud: cloud,
      local: local,
    );
    authStream.add(firstUser);
    await container.read(authStateProvider.future);
    await container.read(cloudRestoreControllerProvider.future);

    final operation = container
        .read(cloudRestoreControllerProvider.notifier)
        .restoreNow();
    await Future<void>.delayed(Duration.zero);
    expect(cloud.lastDownloadUserId, firstUser.id);

    authStream.add(otherUser);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authStateProvider).value?.id, otherUser.id);

    pendingDownload.complete(snapshot);
    await operation;

    final error = container.read(cloudRestoreControllerProvider).error;
    expect(error, isA<CloudBackupException>());
    expect(
      (error! as CloudBackupException).code,
      CloudBackupErrorCode.canceled,
    );
    expect(local.importCallCount, 0);
  });
}

ProviderContainer _buildContainer({
  AuthUser? user,
  Stream<AuthUser?>? authState,
  required FakeCloudBackupRepository cloud,
  required FakeLocalBackupRepository local,
}) {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          authState: authState ?? Stream<AuthUser?>.value(user),
        ),
      ),
      cloudBackupRepositoryProvider.overrideWithValue(cloud),
      localBackupRepositoryProvider.overrideWithValue(local),
    ],
  );
  container.listen(authStateProvider, (_, _) {});
  return container;
}

AuthUser _buildUser({String id = 'user-123', bool verified = true}) {
  return AuthUser(
    id: id,
    email: 'user@example.com',
    isEmailVerified: verified,
    providers: const {AuthProviderType.emailPassword},
  );
}
