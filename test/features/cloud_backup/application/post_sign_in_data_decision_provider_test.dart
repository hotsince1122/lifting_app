import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision_provider.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';

import '../../authentication/test_doubles/fake_auth_repository.dart';
import '../test_doubles/fake_backup_repositories.dart';
import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  for (final scenario in <({String name, AuthUser? user})>[
    (name: 'guest', user: null),
    (name: 'unverified account', user: _user('user-a', verified: false)),
  ]) {
    test('skips local and cloud reads for ${scenario.name}', () async {
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
      final container = _buildContainer(
        user: scenario.user,
        local: local,
        cloud: cloud,
      );

      expect(
        await container.read(postSignInDataDecisionProvider.future),
        isNull,
      );
      expect(local.loadOwnerCallCount, 0);
      expect(local.hasWorkoutProgressCallCount, 0);
      expect(cloud.metadataCallCount, 0);
    });
  }

  test('continues immediately when local data belongs to this UID', () async {
    final local = _local(ownerUid: 'user-a', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    final container = _buildContainer(
      user: _user('user-a'),
      local: local,
      cloud: cloud,
    );

    expect(
      await container.read(postSignInDataDecisionProvider.future),
      SignInDataDecision.continueLocal,
    );
    expect(local.loadOwnerCallCount, 1);
    expect(local.hasWorkoutProgressCallCount, 0);
    expect(cloud.metadataCallCount, 0);
  });

  test('uses cloud metadata when guest workouts exist locally', () async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    final container = _buildContainer(
      user: _user('user-a'),
      local: local,
      cloud: cloud,
    );

    expect(
      await container.read(postSignInDataDecisionProvider.future),
      SignInDataDecision.chooseLocalOrCloud,
    );
    expect(local.hasWorkoutProgressCallCount, 1);
    expect(cloud.lastMetadataUserId, 'user-a');
  });

  test('treats a successful empty metadata response as no backup', () async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    final container = _buildContainer(
      user: _user('user-a'),
      local: local,
      cloud: cloud,
    );

    expect(
      await container.read(postSignInDataDecisionProvider.future),
      SignInDataDecision.chooseTransferOrSignOut,
    );
    expect(cloud.metadataCallCount, 1);
  });

  test(
    'propagates a cloud error instead of treating it as no backup',
    () async {
      final error = StateError('Cloud unavailable');
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(metadataException: error);
      final container = _buildContainer(
        user: _user('user-a'),
        local: local,
        cloud: cloud,
      );

      await expectLater(
        container.read(postSignInDataDecisionProvider.future),
        throwsA(same(error)),
      );
    },
  );

  test(
    'recomputes for the new UID when account changes during metadata',
    () async {
      final auth = StreamController<AuthUser?>();
      addTearDown(auth.close);
      final metadata = Completer<CloudBackupMetadata?>();
      final local = _local(ownerUid: 'user-b', hasWorkouts: true);
      final cloud = FakeCloudBackupRepository(metadataFuture: metadata.future);
      final container = _buildContainer(
        authState: auth.stream,
        local: local,
        cloud: cloud,
      );

      auth.add(_user('user-a'));
      await container.read(authStateProvider.future);
      container.listen(postSignInDataDecisionProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(cloud.lastMetadataUserId, 'user-a');

      auth.add(_user('user-b'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authStateProvider).value?.id, 'user-b');

      metadata.complete(_metadata());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(postSignInDataDecisionProvider).value,
        SignInDataDecision.continueLocal,
      );
    },
  );
}

ProviderContainer _buildContainer({
  AuthUser? user,
  Stream<AuthUser?>? authState,
  required FakeLocalBackupRepository local,
  required FakeCloudBackupRepository cloud,
}) {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          authState: authState ?? Stream<AuthUser?>.value(user),
        ),
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

AuthUser _user(String id, {bool verified = true}) {
  return AuthUser(
    id: id,
    email: 'user@example.com',
    isEmailVerified: verified,
    providers: const {AuthProviderType.emailPassword},
  );
}

CloudBackupMetadata _metadata() {
  return CloudBackupMetadata(
    uploadedAt: DateTime.utc(2026, 10, 1),
    sizeBytes: 1024,
  );
}
