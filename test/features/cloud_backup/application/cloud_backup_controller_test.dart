import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

import '../../authentication/test_doubles/fake_auth_repository.dart';
import '../test_doubles/fake_backup_repositories.dart';
import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  group('CloudBackupController build', () {
    test('loads backup metadata for the authenticated verified user', () async {
      // Arrange
      final user = _buildUser();
      final metadata = _buildMetadata();
      final cloudRepository = FakeCloudBackupRepository(
        metadataResult: metadata,
      );
      final container = _buildContainer(
        user: user,
        cloudRepository: cloudRepository,
      );

      // Act
      final result = await container.read(cloudBackupControllerProvider.future);

      // Assert
      expect(result, same(metadata));
      expect(cloudRepository.metadataCallCount, 1);
      expect(cloudRepository.lastMetadataUserId, user.id);
    });

    test(
      'updates the date for this UID after reading cloud metadata',
      () async {
        final user = _buildUser();
        final metadata = _buildMetadata();
        final cache = FakeLastBackupDateRepository();
        final container = _buildContainer(
          user: user,
          cloudRepository: FakeCloudBackupRepository(metadataResult: metadata),
          cache: cache,
        );

        await container.read(cloudBackupControllerProvider.future);

        expect(await cache.read(user.id), metadata.uploadedAt);
        expect(await cache.read('another-user'), isNull);
      },
    );

    test('clears stale date when cloud confirms no backup', () async {
      final user = _buildUser();
      final cache = FakeLastBackupDateRepository()
        ..dates[user.id] = _buildMetadata().uploadedAt;
      final container = _buildContainer(
        user: user,
        cloudRepository: FakeCloudBackupRepository(),
        cache: cache,
      );

      await container.read(cloudBackupControllerProvider.future);

      expect(await cache.read(user.id), isNull);
    });

    test('keeps the cached date when reading cloud metadata fails', () async {
      final user = _buildUser();
      final date = _buildMetadata().uploadedAt;
      final cache = FakeLastBackupDateRepository()..dates[user.id] = date;
      final container = _buildContainer(
        user: user,
        cloudRepository: FakeCloudBackupRepository(
          metadataException: StateError('Offline'),
        ),
        cache: cache,
      );

      await expectLater(
        container.read(cloudBackupControllerProvider.future),
        throwsStateError,
      );

      expect(await cache.read(user.id), date);
    });

    for (final scenario in <({String name, AuthUser? user})>[
      (name: 'guest', user: null),
      (name: 'user with unverified email', user: _buildUser(verified: false)),
    ]) {
      test('does not request metadata for ${scenario.name}', () async {
        // Arrange
        final cloudRepository = FakeCloudBackupRepository();
        final container = _buildContainer(
          user: scenario.user,
          cloudRepository: cloudRepository,
        );

        // Act
        final result = await container.read(
          cloudBackupControllerProvider.future,
        );

        // Assert
        expect(result, isNull);
        expect(cloudRepository.metadataCallCount, 0);
      });
    }
  });

  group('CloudBackupController backupNow', () {
    test('exports and uploads the snapshot for the current user', () async {
      // Arrange
      final user = _buildUser();
      final snapshot = buildBackupSnapshotFixture();
      final uploadedMetadata = _buildMetadata(sizeBytes: 2048);
      final localRepository = FakeLocalBackupRepository(
        snapshot: snapshot,
        ownerUid: user.id,
      );
      final cloudRepository = FakeCloudBackupRepository(
        uploadResult: uploadedMetadata,
      );
      final container = _buildContainer(
        user: user,
        localRepository: localRepository,
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);

      // Act
      await container.read(cloudBackupControllerProvider.notifier).backupNow();

      // Assert
      expect(localRepository.exportCallCount, 1);
      expect(localRepository.loadOwnerCallCount, 2);
      expect(localRepository.claimCallCount, 0);
      expect(cloudRepository.uploadCallCount, 1);
      expect(cloudRepository.lastUploadUserId, user.id);
      expect(cloudRepository.lastUploadedSnapshot, same(snapshot));
      expect(
        container.read(cloudBackupControllerProvider).value,
        same(uploadedMetadata),
      );
      expect(
        await container.read(lastBackupDateRepositoryProvider).read(user.id),
        uploadedMetadata.uploadedAt,
      );
    });

    test(
      'does not claim or upload unowned data over an existing backup',
      () async {
        final user = _buildUser();
        final localRepository = FakeLocalBackupRepository(
          snapshot: buildBackupSnapshotFixture(),
        );
        final cloudRepository = FakeCloudBackupRepository(
          metadataResult: _buildMetadata(),
          uploadResult: _buildMetadata(),
        );
        final container = _buildContainer(
          user: user,
          localRepository: localRepository,
          cloudRepository: cloudRepository,
        );
        await container.read(cloudBackupControllerProvider.future);

        await container
            .read(cloudBackupControllerProvider.notifier)
            .backupNow();

        expect(localRepository.loadOwnerCallCount, 1);
        expect(
          container.read(cloudBackupControllerProvider).error,
          isA<StateError>(),
        );
        expect(localRepository.claimCallCount, 0);
        expect(localRepository.ownerUid, isNull);
        expect(localRepository.exportCallCount, 0);
        expect(cloudRepository.uploadCallCount, 0);
      },
    );

    test('does not export or upload data owned by another UID', () async {
      final localRepository = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: 'another-user',
      );
      final cloudRepository = FakeCloudBackupRepository(
        uploadResult: _buildMetadata(),
      );
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: localRepository,
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);

      await container.read(cloudBackupControllerProvider.notifier).backupNow();

      final state = container.read(cloudBackupControllerProvider);
      expect(state.hasError, isTrue);
      expect(localRepository.loadOwnerCallCount, 1);
      expect(localRepository.claimCallCount, 0);
      expect(localRepository.ownerUid, 'another-user');
      expect(localRepository.exportCallCount, 0);
      expect(cloudRepository.uploadCallCount, 0);
    });

    test('returns a typed error for a guest without exporting', () async {
      // Arrange
      final localRepository = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
      );
      final cloudRepository = FakeCloudBackupRepository();
      final container = _buildContainer(
        user: null,
        localRepository: localRepository,
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);

      // Act
      await container.read(cloudBackupControllerProvider.notifier).backupNow();

      // Assert
      final state = container.read(cloudBackupControllerProvider);
      expect(state.error, isA<CloudBackupException>());
      expect(
        (state.error! as CloudBackupException).code,
        CloudBackupErrorCode.unauthenticated,
      );
      expect(localRepository.exportCallCount, 0);
      expect(cloudRepository.uploadCallCount, 0);
    });

    test(
      'returns a typed error for an unverified user without exporting',
      () async {
        // Arrange
        final localRepository = FakeLocalBackupRepository(
          snapshot: buildBackupSnapshotFixture(),
        );
        final cloudRepository = FakeCloudBackupRepository();
        final container = _buildContainer(
          user: _buildUser(verified: false),
          localRepository: localRepository,
          cloudRepository: cloudRepository,
        );
        await container.read(cloudBackupControllerProvider.future);

        // Act
        await container
            .read(cloudBackupControllerProvider.notifier)
            .backupNow();

        // Assert
        final state = container.read(cloudBackupControllerProvider);
        expect(state.error, isA<CloudBackupException>());
        expect(
          (state.error! as CloudBackupException).code,
          CloudBackupErrorCode.emailNotVerified,
        );
        expect(localRepository.exportCallCount, 0);
        expect(cloudRepository.uploadCallCount, 0);
      },
    );

    test('preserves the previous metadata when upload fails', () async {
      // Arrange
      const expectedException = CloudBackupException(
        CloudBackupErrorCode.quotaExceeded,
      );
      final previousMetadata = _buildMetadata(sizeBytes: 1024);
      final uploadCompleter = Completer<CloudBackupMetadata>();
      final cloudRepository = FakeCloudBackupRepository(
        metadataResult: previousMetadata,
        uploadFuture: uploadCompleter.future,
      );
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: FakeLocalBackupRepository(
          snapshot: buildBackupSnapshotFixture(),
          ownerUid: 'user-123',
        ),
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);
      final controller = container.read(cloudBackupControllerProvider.notifier);

      // Act
      final operation = controller.backupNow();
      await Future<void>.delayed(Duration.zero);

      final loadingState = container.read(cloudBackupControllerProvider);
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.value, same(previousMetadata));

      uploadCompleter.completeError(expectedException);
      await operation;

      // Assert
      final errorState = container.read(cloudBackupControllerProvider);
      expect(errorState.error, same(expectedException));
      expect(errorState.value, same(previousMetadata));
    });

    test('does not upload when exporting the local snapshot fails', () async {
      // Arrange
      final expectedException = StateError('Export failed.');
      final localRepository = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: 'user-123',
        exportException: expectedException,
      );
      final cloudRepository = FakeCloudBackupRepository();
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: localRepository,
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);

      // Act
      await container.read(cloudBackupControllerProvider.notifier).backupNow();

      // Assert
      expect(
        container.read(cloudBackupControllerProvider).error,
        same(expectedException),
      );
      expect(localRepository.exportCallCount, 1);
      expect(cloudRepository.uploadCallCount, 0);
    });

    test(
      'cache failure does not turn a successful upload into an error',
      () async {
        final metadata = _buildMetadata();
        final cache = FakeLastBackupDateRepository()..throwOnWrite = true;
        final container = _buildContainer(
          user: _buildUser(),
          cloudRepository: FakeCloudBackupRepository(uploadResult: metadata),
          cache: cache,
        );
        await container.read(cloudBackupControllerProvider.future);

        await container
            .read(cloudBackupControllerProvider.notifier)
            .backupNow();

        expect(
          container.read(cloudBackupControllerProvider).value,
          same(metadata),
        );
      },
    );

    test('ignores a second backup while the first is loading', () async {
      // Arrange
      final exportCompleter = Completer<void>();
      final localRepository = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: 'user-123',
        exportFuture: exportCompleter.future,
      );
      final cloudRepository = FakeCloudBackupRepository(
        uploadResult: _buildMetadata(),
      );
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: localRepository,
        cloudRepository: cloudRepository,
      );
      await container.read(cloudBackupControllerProvider.future);
      final controller = container.read(cloudBackupControllerProvider.notifier);

      // Act
      final firstOperation = controller.backupNow();
      await Future<void>.delayed(Duration.zero);
      await controller.backupNow();

      // Assert
      expect(localRepository.exportCallCount, 1);
      expect(cloudRepository.uploadCallCount, 0);

      exportCompleter.complete();
      await firstOperation;

      expect(cloudRepository.uploadCallCount, 1);
      expect(container.read(cloudBackupControllerProvider).hasValue, isTrue);
    });

    test('cancels when local ownership changes during export', () async {
      final exported = Completer<void>();
      final local = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: 'user-123',
        exportFuture: exported.future,
      );
      final cloud = FakeCloudBackupRepository(uploadResult: _buildMetadata());
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: local,
        cloudRepository: cloud,
      );
      await container.read(cloudBackupControllerProvider.future);

      final operation = container
          .read(cloudBackupControllerProvider.notifier)
          .backupNow();
      await Future<void>.delayed(Duration.zero);
      expect(local.exportCallCount, 1);
      local.ownerUid = 'another-user';
      exported.complete();
      await operation;

      final error = container.read(cloudBackupControllerProvider).error;
      expect(error, isA<CloudBackupException>());
      expect(
        (error! as CloudBackupException).code,
        CloudBackupErrorCode.canceled,
      );
      expect(cloud.uploadCallCount, 0);
    });

    test('does not upload after disposal during export', () async {
      final exported = Completer<void>();
      final local = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: 'user-123',
        exportFuture: exported.future,
      );
      final cloud = FakeCloudBackupRepository(uploadResult: _buildMetadata());
      final container = _buildContainer(
        user: _buildUser(),
        localRepository: local,
        cloudRepository: cloud,
      );
      await container.read(cloudBackupControllerProvider.future);
      final operation = container
          .read(cloudBackupControllerProvider.notifier)
          .backupNow();
      await Future<void>.delayed(Duration.zero);
      expect(local.exportCallCount, 1);

      container.dispose();
      exported.complete();
      await operation;

      expect(cloud.uploadCallCount, 0);
    });
  });

  group('CloudBackupController session changes', () {
    for (final scenario in <({String name, List<AuthUser?> users})>[
      (name: 'sign out', users: [null]),
      (name: 'another account', users: [_buildUser(id: 'user-b')]),
      (
        name: 'email verification is lost',
        users: [_buildUser(verified: false)],
      ),
      (
        name: 'sign out and back into the same account',
        users: [null, _buildUser()],
      ),
    ]) {
      test('does not upload after ${scenario.name} during export', () async {
        final auth = StreamController<AuthUser?>();
        addTearDown(auth.close);
        final exported = Completer<void>();
        final local = FakeLocalBackupRepository(
          snapshot: buildBackupSnapshotFixture(),
          ownerUid: 'user-123',
          exportFuture: exported.future,
        );
        final cloud = FakeCloudBackupRepository(
          metadataResult: _buildMetadata(),
          uploadResult: _buildMetadata(sizeBytes: 2048),
        );
        final container = _buildContainer(
          user: _buildUser(),
          authState: auth.stream,
          localRepository: local,
          cloudRepository: cloud,
        );
        await _changeUser(container, auth, _buildUser());

        final operation = container
            .read(cloudBackupControllerProvider.notifier)
            .backupNow();
        await Future<void>.delayed(Duration.zero);
        expect(local.exportCallCount, 1);
        for (final user in scenario.users) {
          await _changeUser(container, auth, user);
        }
        final currentState = container.read(cloudBackupControllerProvider);

        exported.complete();
        await operation;

        expect(cloud.uploadCallCount, 0);
        expect(local.claimCallCount, 0);
        expect(
          container.read(cloudBackupControllerProvider),
          same(currentState),
        );
      });
    }

    for (final fails in [false, true]) {
      for (final returnsToSameAccount in [false, true]) {
        test(
          'ignores old upload ${fails ? 'failure' : 'success'} after '
          '${returnsToSameAccount ? 'signing back into the same account' : 'switching accounts'}',
          () async {
            final auth = StreamController<AuthUser?>();
            addTearDown(auth.close);
            final uploaded = Completer<CloudBackupMetadata>();
            final cloud = FakeCloudBackupRepository(
              metadataResult: _buildMetadata(),
              uploadFuture: uploaded.future,
            );
            final cache = FakeLastBackupDateRepository();
            final container = _buildContainer(
              user: _buildUser(),
              authState: auth.stream,
              cloudRepository: cloud,
              cache: cache,
            );
            await _changeUser(container, auth, _buildUser());

            final operation = container
                .read(cloudBackupControllerProvider.notifier)
                .backupNow();
            await Future<void>.delayed(Duration.zero);
            expect(cloud.uploadCallCount, 1);
            expect(cloud.lastUploadUserId, 'user-123');
            await _changeUser(container, auth, _buildUser(id: 'user-b'));
            if (returnsToSameAccount) {
              await _changeUser(container, auth, _buildUser());
            }
            final currentState = container.read(cloudBackupControllerProvider);
            final currentDates = Map<String, DateTime>.of(cache.dates);

            if (fails) {
              uploaded.completeError(
                const CloudBackupException(
                  CloudBackupErrorCode.permissionDenied,
                ),
              );
            } else {
              uploaded.complete(
                CloudBackupMetadata(
                  uploadedAt: DateTime.utc(2026, 10, 8),
                  sizeBytes: 2048,
                ),
              );
            }
            await operation;

            expect(
              container.read(cloudBackupControllerProvider),
              same(currentState),
            );
            expect(cache.dates, currentDates);
          },
        );
      }
    }

    for (final backupExists in [false, true]) {
      test(
        'ignores old metadata after logout (backup exists: $backupExists)',
        () async {
          final auth = StreamController<AuthUser?>();
          addTearDown(auth.close);
          final metadata = Completer<CloudBackupMetadata?>();
          final oldDate = DateTime.utc(2026, 9, 1);
          final cache = FakeLastBackupDateRepository()
            ..dates['user-123'] = oldDate;
          final cloud = FakeCloudBackupRepository(
            metadataFuture: metadata.future,
          );
          final container = _buildContainer(
            user: _buildUser(),
            authState: auth.stream,
            cloudRepository: cloud,
            cache: cache,
          );
          auth.add(_buildUser());
          await container.read(authStateProvider.future);
          container.listen(cloudBackupControllerProvider, (_, _) {});
          await Future<void>.delayed(Duration.zero);
          expect(cloud.metadataCallCount, 1);

          await _changeUser(container, auth, null);
          metadata.complete(backupExists ? _buildMetadata() : null);
          await Future<void>.delayed(Duration.zero);

          expect(container.read(cloudBackupControllerProvider).value, isNull);
          expect(
            container.read(cloudBackupControllerProvider).hasError,
            isFalse,
          );
          expect(cache.dates['user-123'], oldDate);
        },
      );
    }
  });
}

Future<void> _changeUser(
  ProviderContainer container,
  StreamController<AuthUser?> auth,
  AuthUser? user,
) async {
  auth.add(user);
  await Future<void>.delayed(Duration.zero);
  await container.read(cloudBackupControllerProvider.future);
}

ProviderContainer _buildContainer({
  required AuthUser? user,
  Stream<AuthUser?>? authState,
  required FakeCloudBackupRepository cloudRepository,
  FakeLocalBackupRepository? localRepository,
  FakeLastBackupDateRepository? cache,
}) {
  final local =
      localRepository ??
      FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
        ownerUid: user?.id,
      );

  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          authState: authState ?? Stream<AuthUser?>.value(user),
        ),
      ),
      localBackupRepositoryProvider.overrideWithValue(local),
      cloudBackupRepositoryProvider.overrideWithValue(cloudRepository),
      lastBackupDateRepositoryProvider.overrideWithValue(
        cache ?? FakeLastBackupDateRepository(),
      ),
    ],
  );

  container.listen(authStateProvider, (_, _) {});

  return container;
}

AuthUser _buildUser({bool verified = true, String id = 'user-123'}) {
  return AuthUser(
    id: id,
    email: 'user@example.com',
    isEmailVerified: verified,
    providers: const {AuthProviderType.emailPassword},
  );
}

CloudBackupMetadata _buildMetadata({int sizeBytes = 1024}) {
  return CloudBackupMetadata(
    uploadedAt: DateTime.utc(2026, 9, 23, 10),
    sizeBytes: sizeBytes,
  );
}
