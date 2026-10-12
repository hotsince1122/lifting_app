import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/app/shell/main_bottom_navigation.dart';
import 'package:lifting_tracker_app/app/shell/main_shell.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/simple_app_bar.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/sign_in_data_gate.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/page/account_and_backup_page.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/pages/home_page.dart';

import '../../../features/authentication/test_doubles/fake_auth_repository.dart';
import '../../../features/cloud_backup/test_doubles/fake_backup_repositories.dart';
import '../../../features/cloud_backup/test_fixtures/backup_snapshot_fixture.dart';

void main() {
  testWidgets('guests can use the app without a conflict check', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(null)),
      local: local,
      cloud: cloud,
    );

    expect(find.text('APP'), findsOneWidget);
    expect(_gateBarrier, findsNothing);
    expect(local.loadOwnerCallCount, 0);
    expect(cloud.metadataCallCount, 0);
  });

  testWidgets('an unverified account can keep using local data', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(
        authState: Stream.value(_user('user-a', verified: false)),
      ),
      local: local,
      cloud: cloud,
    );

    expect(_gateBarrier, findsNothing);
    expect(local.loadOwnerCallCount, 0);
    expect(cloud.metadataCallCount, 0);
  });

  testWidgets('a saved session with its own local data enters the app', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-a', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(_gateBarrier, findsNothing);
    expect(local.loadOwnerCallCount, 1);
    expect(cloud.metadataCallCount, 0);
  });

  testWidgets('main shell keeps its real navigation during startup check', (
    tester,
  ) async {
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: authStream.stream),
      local: _local(ownerUid: 'user-a', hasWorkouts: true),
      cloud: FakeCloudBackupRepository(),
      home: const MainShell(),
      wrapHomeForLoading: false,
      settle: false,
    );

    expect(find.byType(MainBottomNavigation), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('account page shows only a spinner while checking', (
    tester,
  ) async {
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: authStream.stream),
      local: _local(ownerUid: 'user-a', hasWorkouts: true),
      cloud: FakeCloudBackupRepository(),
      home: const AccountAndBackupPage(),
      wrapHomeForLoading: false,
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SimpleAppBar), findsNothing);
    expect(find.byType(MainBottomNavigation), findsNothing);
  });

  testWidgets('startup check shows no popup and finishes for same owner', (
    tester,
  ) async {
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    final cloud = FakeCloudBackupRepository();
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: authStream.stream),
      local: _local(ownerUid: 'user-a', hasWorkouts: true),
      cloud: cloud,
      settle: false,
    );

    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    authStream.add(_user('user-a'));
    await tester.pumpAndSettle();

    expect(_gateBarrier, findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('APP'), findsOneWidget);
    expect(cloud.metadataCallCount, 0);
  });

  testWidgets('automatically attaches unowned data when no backup exists', (
    tester,
  ) async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository();
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(local.ownerUid, 'user-a');
    expect(local.claimCallCount, 1);
    expect(cloud.uploadCallCount, 0);
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('keeps local setup when a cloud backup is offered', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: false);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(find.text('Cloud backup available'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Keep local data'));
    await tester.pumpAndSettle();

    expect(local.ownerUid, 'user-a');
    expect(local.reassignOwnerIfNoWorkoutsCallCount, 1);
    expect(cloud.uploadCallCount, 0);
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('keeps guest workouts without uploading over a cloud backup', (
    tester,
  ) async {
    final local = _local(ownerUid: null, hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(find.text('Choose your workout data'), findsOneWidget);
    await tester.tap(find.text('Keep local data'));
    await tester.pumpAndSettle();

    expect(local.ownerUid, 'user-a');
    expect(local.claimCallCount, 1);
    expect(cloud.uploadCallCount, 0);
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('requires an explicit choice for another account’s workouts', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(find.text('Workouts from another account'), findsOneWidget);
    expect(local.ownerUid, 'user-b');
    await tester.tap(find.text('Use local workouts'));
    await tester.pumpAndSettle();

    expect(local.ownerUid, 'user-a');
    expect(local.reassignOwnerCallCount, 1);
    expect(cloud.uploadCallCount, 0);
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('blocks workout actions behind an unresolved conflict', (
    tester,
  ) async {
    var workoutStarts = 0;
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: FakeCloudBackupRepository(metadataResult: _metadata()),
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => workoutStarts++,
          child: const Text('Start workout'),
        ),
      ),
    );

    await tester.tap(find.text('Start workout'), warnIfMissed: false);
    await tester.pump();
    expect(workoutStarts, 0);

    await tester.tap(find.text('Use local workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    expect(workoutStarts, 1);
  });

  testWidgets('restores after choosing the cloud backup', (tester) async {
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
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    await tester.tap(find.text('Restore backup'));
    await tester.pumpAndSettle();

    expect(local.ownerUid, 'user-a');
    expect(local.importCallCount, 1);
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('keeps the conflict open when a backup disappears', (
    tester,
  ) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    await tester.tap(find.text('Restore backup'));
    await tester.pumpAndSettle();

    expect(local.ownerUid, 'user-b');
    expect(local.importCallCount, 0);
    expect(_gateBarrier, findsOneWidget);
    expect(
      find.text('That cloud backup is no longer available.'),
      findsOneWidget,
    );
  });

  testWidgets('cloud errors keep data blocked and offer retry', (tester) async {
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(
      metadataException: StateError('Offline'),
    );
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: Stream.value(_user('user-a'))),
      local: local,
      cloud: cloud,
    );

    expect(find.text('Could not check your backup'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(local.ownerUid, 'user-b');

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(cloud.metadataCallCount, greaterThan(1));
    expect(find.text('Could not check your backup'), findsOneWidget);
  });

  testWidgets('signing out leaves another account’s workouts in place', (
    tester,
  ) async {
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    final auth = FakeAuthRepository(authState: authStream.stream);
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    await _pumpGate(
      tester,
      auth: auth,
      local: local,
      cloud: FakeCloudBackupRepository(),
      settle: false,
    );
    authStream.add(_user('user-a'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    authStream.add(null);
    await tester.pumpAndSettle();

    expect(auth.signOutCallCount, 1);
    expect(local.ownerUid, 'user-b');
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('discards an older account’s pending cloud decision', (
    tester,
  ) async {
    var workoutStarts = 0;
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    final metadata = Completer<CloudBackupMetadata?>();
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataFuture: metadata.future);
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: authStream.stream),
      local: local,
      cloud: cloud,
      settle: false,
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => workoutStarts++,
          child: const Text('Start workout'),
        ),
      ),
    );

    authStream.add(_user('user-a'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(cloud.lastMetadataUserId, 'user-a');
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(workoutStarts, 0);

    authStream.add(_user('user-b'));
    await tester.pumpAndSettle();
    expect(_gateBarrier, findsNothing);
    expect(find.text('Workouts from another account'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Start workout'));
    expect(workoutStarts, 1);

    metadata.complete(_metadata());
    await tester.pumpAndSettle();
    expect(_gateBarrier, findsNothing);
  });

  testWidgets('covers a sign in started on a pushed route', (tester) async {
    final authStream = StreamController<AuthUser?>();
    addTearDown(authStream.close);
    final local = _local(ownerUid: 'user-b', hasWorkouts: true);
    final cloud = FakeCloudBackupRepository(metadataResult: _metadata());
    await _pumpGate(
      tester,
      auth: FakeAuthRepository(authState: authStream.stream),
      local: local,
      cloud: cloud,
      settle: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('SIGN IN ROUTE')),
              ),
            ),
            child: const Text('Open account'),
          ),
        ),
      ),
    );
    authStream.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN ROUTE'), findsOneWidget);

    authStream.add(_user('user-a'));
    await tester.pumpAndSettle();

    expect(find.text('Workouts from another account'), findsOneWidget);
    expect(find.text('SIGN IN ROUTE'), findsOneWidget);
  });
}

Future<void> _pumpGate(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  required FakeLocalBackupRepository local,
  required FakeCloudBackupRepository cloud,
  Widget? home,
  bool wrapHomeForLoading = true,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        localBackupRepositoryProvider.overrideWithValue(local),
        cloudBackupRepositoryProvider.overrideWithValue(cloud),
        lastBackupDateRepositoryProvider.overrideWithValue(
          FakeLastBackupDateRepository(),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => SignInDataGate(child: child!),
        home: wrapHomeForLoading
            ? Builder(
                builder: (context) => SignInDataGate.isLoading(context)
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      )
                    : home ?? const Scaffold(body: Text('APP')),
              )
            : home ?? const Scaffold(body: Text('APP')),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

final Finder _gateBarrier = find.byWidgetPredicate(
  (widget) => widget is ModalBarrier && widget.color == Colors.black54,
);

FakeLocalBackupRepository _local({
  required String? ownerUid,
  required bool hasWorkouts,
}) => FakeLocalBackupRepository(
  snapshot: buildBackupSnapshotFixture(),
  ownerUid: ownerUid,
  hasWorkoutProgressValue: hasWorkouts,
);

CloudBackupMetadata _metadata() =>
    CloudBackupMetadata(uploadedAt: DateTime.utc(2026, 10, 4), sizeBytes: 128);

AuthUser _user(String id, {bool verified = true}) => AuthUser(
  id: id,
  email: 'user@example.com',
  isEmailVerified: verified,
  providers: const {AuthProviderType.emailPassword},
);
