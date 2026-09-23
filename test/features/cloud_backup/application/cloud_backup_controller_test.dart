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
      final localRepository = FakeLocalBackupRepository(snapshot: snapshot);
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
      expect(cloudRepository.uploadCallCount, 1);
      expect(cloudRepository.lastUploadUserId, user.id);
      expect(cloudRepository.lastUploadedSnapshot, same(snapshot));
      expect(
        container.read(cloudBackupControllerProvider).value,
        same(uploadedMetadata),
      );
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

    test('ignores a second backup while the first is loading', () async {
      // Arrange
      final exportCompleter = Completer<void>();
      final localRepository = FakeLocalBackupRepository(
        snapshot: buildBackupSnapshotFixture(),
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
  });
}

ProviderContainer _buildContainer({
  required AuthUser? user,
  required FakeCloudBackupRepository cloudRepository,
  FakeLocalBackupRepository? localRepository,
}) {
  final local =
      localRepository ??
      FakeLocalBackupRepository(snapshot: buildBackupSnapshotFixture());

  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(authState: Stream<AuthUser?>.value(user)),
      ),
      localBackupRepositoryProvider.overrideWithValue(local),
      cloudBackupRepositoryProvider.overrideWithValue(cloudRepository),
    ],
  );

  container.listen(authStateProvider, (_, _) {});

  return container;
}

AuthUser _buildUser({bool verified = true}) {
  return AuthUser(
    id: 'user-123',
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
