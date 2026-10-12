import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_restore_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_metadata.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/widgets/progress_protection_notice.dart';

import '../../../../features/authentication/test_doubles/fake_auth_repository.dart';

class _NoticeBackupController extends CloudBackupController {
  @override
  Future<CloudBackupMetadata?> build() async => null;

  void fail(Object error) => state = AsyncError(error, StackTrace.current);
  void retry() => state = const AsyncLoading();
  void succeed() => state = const AsyncData(null);
}

class _NoticeRestoreController extends CloudRestoreController {
  @override
  FutureOr<RestoreResult?> build() => null;

  void start() => state = const AsyncLoading();
  void noBackup() => state = const AsyncData(RestoreResult.noBackup);
  void fail(Object error) => state = AsyncError(error, StackTrace.current);
  void succeed() => state = const AsyncData(RestoreResult.restored);
}

void main() {
  final verifiedUser = AuthUser(
    id: 'user-123',
    email: 'alex@example.com',
    isEmailVerified: true,
    providers: {AuthProviderType.emailPassword},
  );

  Future<void> pumpProgressProtectionNotice(
    WidgetTester tester, {
    required AuthUser? user,
    _NoticeBackupController? controller,
    _NoticeRestoreController? restoreController,
  }) async {
    final fakeRepository = FakeAuthRepository(authState: Stream.value(user));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          cloudBackupControllerProvider.overrideWith(
            () => controller ?? _NoticeBackupController(),
          ),
          cloudRestoreControllerProvider.overrideWith(
            () => restoreController ?? _NoticeRestoreController(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: ProgressProtectionNotice()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows the backup warning for a guest', (tester) async {
    await pumpProgressProtectionNotice(tester, user: null);

    expect(find.text('Your progress isn’t backed up'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets('asks an unverified user to verify their email', (tester) async {
    final user = AuthUser(
      id: 'user-123',
      email: 'alex@example.com',
      isEmailVerified: false,
      providers: {AuthProviderType.emailPassword},
    );

    await pumpProgressProtectionNotice(tester, user: user);

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Check verification status'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
  });

  testWidgets('hides the notice for a verified user', (tester) async {
    final user = AuthUser(
      id: 'user-123',
      email: 'alex@example.com',
      isEmailVerified: true,
      providers: {AuthProviderType.emailPassword},
    );

    await pumpProgressProtectionNotice(tester, user: user);

    expect(find.text('Your progress isn’t backed up'), findsNothing);
    expect(find.text('Verify your email'), findsNothing);
  });

  testWidgets('shows restore loading, no backup, error and success inline', (
    tester,
  ) async {
    final restoreController = _NoticeRestoreController();
    await pumpProgressProtectionNotice(
      tester,
      user: verifiedUser,
      restoreController: restoreController,
    );

    restoreController.start();
    await tester.pump();
    await tester.pump();
    expect(find.text('Restoring backup…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    restoreController.noBackup();
    await tester.pumpAndSettle();
    expect(find.text('No cloud backup found'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    restoreController.fail(
      const CloudBackupException(CloudBackupErrorCode.permissionDenied),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not restore backup'), findsOneWidget);
    expect(
      find.text('Your account could not access this backup.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);

    restoreController.succeed();
    await tester.pumpAndSettle();
    expect(find.text('Backup restored'), findsOneWidget);
    expect(find.text('Could not restore backup'), findsNothing);
  });

  testWidgets('restore feedback takes priority over a backup error', (
    tester,
  ) async {
    final backupController = _NoticeBackupController();
    final restoreController = _NoticeRestoreController();
    await pumpProgressProtectionNotice(
      tester,
      user: verifiedUser,
      controller: backupController,
      restoreController: restoreController,
    );

    backupController.fail(
      const CloudBackupException(CloudBackupErrorCode.quotaExceeded),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cloud backup unavailable'), findsOneWidget);

    restoreController.start();
    await tester.pump();
    await tester.pump();
    expect(find.text('Restoring backup…'), findsOneWidget);
    expect(find.text('Cloud backup unavailable'), findsNothing);
  });

  final errorTitles = {
    CloudBackupErrorCode.unauthenticated: 'Sign in required',
    CloudBackupErrorCode.emailNotVerified: 'Verify your email',
    CloudBackupErrorCode.permissionDenied: 'Cloud backup access denied',
    CloudBackupErrorCode.quotaExceeded: 'Cloud backup unavailable',
    CloudBackupErrorCode.configurationError: 'Cloud backup unavailable',
    CloudBackupErrorCode.retryLimitExceeded: 'Cloud backup request timed out',
    CloudBackupErrorCode.canceled: 'Cloud backup request canceled',
    CloudBackupErrorCode.transferIntegrityFailed: 'Backup transfer failed',
    CloudBackupErrorCode.sizeLimitExceeded: 'Backup too large',
    CloudBackupErrorCode.unknown: 'Could not complete cloud backup request',
  };

  for (final entry in errorTitles.entries) {
    testWidgets('shows inline feedback for ${entry.key.name}', (tester) async {
      final controller = _NoticeBackupController();
      await pumpProgressProtectionNotice(
        tester,
        user: verifiedUser,
        controller: controller,
      );
      controller.fail(CloudBackupException(entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      if (entry.key == CloudBackupErrorCode.emailNotVerified) {
        expect(find.text('Check verification status'), findsOneWidget);
      }
    });
  }

  testWidgets(
    'handles unexpected errors and clears feedback during retry and success',
    (tester) async {
      final controller = _NoticeBackupController();
      await pumpProgressProtectionNotice(
        tester,
        user: verifiedUser,
        controller: controller,
      );
      controller.fail(StateError('SQLite export failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not complete cloud backup request'),
        findsOneWidget,
      );

      controller.retry();
      await tester.pumpAndSettle();
      expect(
        find.text('Could not complete cloud backup request'),
        findsNothing,
      );

      controller.succeed();
      await tester.pumpAndSettle();
      expect(
        find.text('Could not complete cloud backup request'),
        findsNothing,
      );
    },
  );

  testWidgets('guest notice takes priority over a previous backup error', (
    tester,
  ) async {
    final controller = _NoticeBackupController();
    await pumpProgressProtectionNotice(
      tester,
      user: verifiedUser,
      controller: controller,
    );
    controller.fail(
      const CloudBackupException(CloudBackupErrorCode.permissionDenied),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cloud backup access denied'), findsOneWidget);

    final context = tester.element(find.byType(ProgressProtectionNotice));
    final container = ProviderScope.containerOf(context);
    container.updateOverrides([
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(authState: Stream.value(null)),
      ),
      cloudBackupControllerProvider.overrideWith(() => controller),
      cloudRestoreControllerProvider.overrideWith(_NoticeRestoreController.new),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Your progress isn’t backed up'), findsOneWidget);
    expect(find.text('Cloud backup access denied'), findsNothing);
  });
}
