import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_resolution_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

import '../../authentication/test_doubles/fake_auth_repository.dart';
import '../test_doubles/fake_backup_repositories.dart';
import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  test('attaches unowned workouts only when no cloud backup exists', () async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.attachLocal,
      action: SignInDataAction.attachLocal,
    );

    expect(local.ownerUid, 'user-a');
    expect(local.claimCallCount, 1);
    expect(local.reassignOwnerIfNoWorkoutsCallCount, 0);
    expect(cloud.uploadCallCount, 0);
    expect(cloud.downloadCallCount, 0);
    expect(_result(container), SignInDataResolution.localAttached);
  });

  test(
    'attaches another owner with no workouts through the guarded command',
    () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: false);
      final container = _container(
        local: local,
        cloud: FakeCloudBackupRepository(),
      );

      await _resolve(
        container,
        decision: SignInDataDecision.attachLocal,
        action: SignInDataAction.attachLocal,
      );

      expect(local.ownerUid, 'user-a');
      expect(local.reassignOwnerIfNoWorkoutsCallCount, 1);
      expect(_result(container), SignInDataResolution.localAttached);
    },
  );

  test('keeps guest workouts without overwriting the cloud backup', () async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.chooseLocalOrCloud,
      action: SignInDataAction.keepLocal,
    );

    expect(local.ownerUid, 'user-a');
    expect(local.claimCallCount, 1);
    expect(cloud.uploadCallCount, 0);
    expect(_result(container), SignInDataResolution.localAttached);
  });

  test(
    'declining restore safely attaches a database with no workouts',
    () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: false);
      final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
      final container = _container(local: local, cloud: cloud);

      await _resolve(
        container,
        decision: SignInDataDecision.offerRestore,
        action: SignInDataAction.keepLocal,
      );

      expect(local.ownerUid, 'user-a');
      expect(local.reassignOwnerIfNoWorkoutsCallCount, 1);
      expect(cloud.uploadCallCount, 0);
      expect(_result(container), SignInDataResolution.localAttached);
    },
  );

  test(
    'transfers another account’s workouts only through transferLocal',
    () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
      final container = _container(local: local, cloud: cloud);

      await _resolve(
        container,
        decision: SignInDataDecision.chooseTransferOrCloud,
        action: SignInDataAction.attachLocal,
      );
      expect(
        container.read(postSignInDataResolutionControllerProvider).hasError,
        isTrue,
      );
      expect(local.ownerUid, 'user-b');
      expect(local.reassignOwnerCallCount, 0);

      await _resolve(
        container,
        decision: SignInDataDecision.chooseTransferOrCloud,
        action: SignInDataAction.transferLocal,
      );
      expect(local.ownerUid, 'user-a');
      expect(local.reassignOwnerCallCount, 1);
      expect(local.reassignOwnerIfNoWorkoutsCallCount, 0);
      expect(cloud.uploadCallCount, 0);
      expect(_result(container), SignInDataResolution.localTransferred);
    },
  );

  test(
    'signs out without changing workouts owned by another account',
    () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final auth = FakeAuthRepository(authState: Stream.value(_user('user-a')));
      final cloud = FakeCloudBackupRepository();
      final container = _container(local: local, cloud: cloud, auth: auth);

      await _resolve(
        container,
        decision: SignInDataDecision.chooseTransferOrSignOut,
        action: SignInDataAction.signOut,
      );

      expect(auth.signOutCallCount, 1);
      expect(local.ownerUid, 'user-b');
      expect(local.reassignOwnerCallCount, 0);
      expect(cloud.metadataCallCount, 0);
      expect(_result(container), SignInDataResolution.signedOut);
    },
  );

  test('restores cloud data using the existing restore operation', () async {
    final snapshot = buildBackupSnapshotFixture();
    final local = FakeLocalBackupRepository(
      snapshot: snapshot,
      ownerUid: 'user-b',
      hasWorkoutProgressValue: true,
    );
    final cloud = FakeCloudBackupRepository(
      metadataResult: _metadata(),
      downloadResult: snapshot,
    );
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.chooseTransferOrCloud,
      action: SignInDataAction.restoreCloud,
    );

    expect(cloud.downloadCallCount, 1);
    expect(local.importCallCount, 1);
    expect(local.ownerUid, 'user-a');
    expect(_result(container), SignInDataResolution.restored);
  });

  test(
    'reports a backup removed after the decision without changing local data',
    () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
      final container = _container(local: local, cloud: cloud);

      await _resolve(
        container,
        decision: SignInDataDecision.chooseTransferOrCloud,
        action: SignInDataAction.restoreCloud,
      );

      expect(local.ownerUid, 'user-b');
      expect(local.importCallCount, 0);
      expect(_result(container), SignInDataResolution.noBackup);
    },
  );

  test('keeps local data and reports a restore download error', () async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final failure = StateError('Download failed');
    final cloud = FakeCloudBackupRepository(
      metadataResult: _metadata(),
      downloadException: failure,
    );
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.chooseTransferOrCloud,
      action: SignInDataAction.restoreCloud,
    );

    expect(
      container.read(postSignInDataResolutionControllerProvider).error,
      same(failure),
    );
    expect(local.ownerUid, 'user-b');
    expect(local.importCallCount, 0);
  });

  test('rejects a decision that changed before the user chose', () async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.attachLocal,
      action: SignInDataAction.attachLocal,
    );

    final error = container
        .read(postSignInDataResolutionControllerProvider)
        .error;
    expect(error, isA<CloudBackupException>());
    expect(
      (error! as CloudBackupException).code,
      CloudBackupErrorCode.canceled,
    );
    expect(local.ownerUid, isNull);
  });

  test(
    'does not attach data if the account changes during the cloud check',
    () async {
      final authStream = StreamController<AuthUser?>();
      addTearDown(authStream.close);
      final pendingMetadata = Completer<CloudBackupMetadata?>();
      final local = _local(ownerUid: null, hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(
        metadataFuture: pendingMetadata.future,
      );
      final container = _container(
        local: local,
        cloud: cloud,
        auth: FakeAuthRepository(authState: authStream.stream),
      );
      authStream.add(_user('user-a'));
      await container.read(authStateProvider.future);

      final operation = _resolve(
        container,
        decision: SignInDataDecision.attachLocal,
        action: SignInDataAction.attachLocal,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cloud.lastMetadataUserId, 'user-a');

      authStream.add(_user('user-c'));
      await Future<void>.delayed(Duration.zero);
      pendingMetadata.complete(null);
      await operation;

      final error = container
          .read(postSignInDataResolutionControllerProvider)
          .error;
      expect(error, isA<CloudBackupException>());
      expect(
        (error! as CloudBackupException).code,
        CloudBackupErrorCode.canceled,
      );
      expect(local.ownerUid, isNull);
      expect(local.claimCallCount, 0);
    },
  );

  test('does not attach data when the cloud check fails', () async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(
      metadataException: StateError('Cloud unavailable'),
    );
    final container = _container(local: local, cloud: cloud);

    await _resolve(
      container,
      decision: SignInDataDecision.attachLocal,
      action: SignInDataAction.attachLocal,
    );

    expect(
      container.read(postSignInDataResolutionControllerProvider).hasError,
      isTrue,
    );
    expect(local.ownerUid, isNull);
    expect(local.claimCallCount, 0);
  });
}

ProviderContainer _container({
  required FakeLocalBackupRepository local,
  required FakeCloudBackupRepository cloud,
  FakeAuthRepository? auth,
}) {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      ),
      localBackupRepositoryProvider.overrideWithValue(local),
      cloudBackupRepositoryProvider.overrideWithValue(cloud),
      lastBackupDateRepositoryProvider.overrideWithValue(
        FakeLastBackupDateRepository(),
      ),
    ],
  );
  container.listen(authStateProvider, (_, _) {});
  return container;
}

Future<void> _resolve(
  ProviderContainer container, {
  required SignInDataDecision decision,
  required SignInDataAction action,
}) async {
  await container
      .read(postSignInDataResolutionControllerProvider.notifier)
      .resolve(
        expectedUid: 'user-a',
        expectedDecision: decision,
        action: action,
      );
}

SignInDataResolution? _result(ProviderContainer container) {
  return container.read(postSignInDataResolutionControllerProvider).value;
}

FakeLocalBackupRepository _local({
  required String? ownerUid,
  required bool hasWorkouts,
}) {
  return FakeLocalBackupRepository(
    snapshot: buildBackupSnapshotFixture(),
    ownerUid: ownerUid,
    hasWorkoutProgressValue: hasWorkouts,
  );
}

CloudBackupMetadata _metadata() =>
    CloudBackupMetadata(uploadedAt: DateTime.utc(2026, 10, 1), sizeBytes: 128);

AuthUser _user(String id) => AuthUser(
  id: id,
  email: 'user@example.com',
  isEmailVerified: true,
  providers: const {AuthProviderType.emailPassword},
);
