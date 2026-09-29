import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
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

void main() {
  Future<void> pumpProgressProtectionNotice(
    WidgetTester tester, {
    required AuthUser? user,
    _NoticeBackupController? controller,
  }) async {
    final fakeRepository = FakeAuthRepository(authState: Stream.value(user));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          cloudBackupControllerProvider.overrideWith(
            () => controller ?? _NoticeBackupController(),
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

  final verifiedUser = AuthUser(
    id: 'user-123',
    email: 'alex@example.com',
    isEmailVerified: true,
    providers: {AuthProviderType.emailPassword},
  );

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
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Your progress isn’t backed up'), findsOneWidget);
    expect(find.text('Cloud backup access denied'), findsNothing);
  });
}
