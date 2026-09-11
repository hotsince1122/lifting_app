import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/change_password_modal.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_auth_text_field.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/solid_button_with_loading.dart';

import '../../../test_doubles/fake_auth_repository.dart';

void main() {
  Future<void> pumpChangePasswordModal(
    WidgetTester tester,
    FakeAuthRepository fakeRepository,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: ChangePasswordModal()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Finder fieldWithTitle(String title) {
    return find.descendant(
      of: find.widgetWithText(EmailAuthTextField, title),
      matching: find.byType(TextField),
    );
  }

  Future<void> fillPasswordFields(
    WidgetTester tester, {
    String confirmation = 'new-password',
  }) async {
    await tester.enterText(
      fieldWithTitle('Current password'),
      'current-password',
    );
    await tester.enterText(fieldWithTitle('New password'), 'new-password');
    await tester.enterText(
      fieldWithTitle('Confirm new password'),
      confirmation,
    );
  }

  testWidgets('shows required field errors without calling the repository', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository();
    await pumpChangePasswordModal(tester, fakeRepository);

    // Act
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Change password'),
    );
    await tester.pump();

    // Assert
    expect(find.text('Current password is required.'), findsOneWidget);
    expect(find.text('New password is required.'), findsOneWidget);
    expect(find.text('Confirm your new password.'), findsOneWidget);
    expect(fakeRepository.changePasswordCallCount, 0);
  });

  testWidgets('shows a local error when the new passwords do not match', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository();
    await pumpChangePasswordModal(tester, fakeRepository);

    // Act
    await fillPasswordFields(tester, confirmation: 'different-password');
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Change password'),
    );
    await tester.pump();

    // Assert
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(fakeRepository.changePasswordCallCount, 0);
  });

  testWidgets('shows an incorrect current password error on its field', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository(
      changePasswordException: const AuthException(
        AuthErrorCode.invalidCredentials,
      ),
    );
    await pumpChangePasswordModal(tester, fakeRepository);

    // Act
    await fillPasswordFields(tester);
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Change password'),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Current password is incorrect.'), findsOneWidget);
    expect(fakeRepository.changePasswordCallCount, 1);
  });

  testWidgets('delegates the change and shows success feedback', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository();
    await pumpChangePasswordModal(tester, fakeRepository);

    // Act
    await fillPasswordFields(tester);
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Change password'),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(fakeRepository.changePasswordCallCount, 1);
    expect(fakeRepository.lastCurrentPassword, 'current-password');
    expect(fakeRepository.lastNewPassword, 'new-password');
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('shows loading and ignores another submit while changing', (
    tester,
  ) async {
    // Arrange
    final pendingOperation = Completer<void>();
    final fakeRepository = FakeAuthRepository(
      changePasswordFuture: pendingOperation.future,
    );
    await pumpChangePasswordModal(tester, fakeRepository);
    await fillPasswordFields(tester);

    // Act
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Change password'),
    );
    await tester.pump();

    // Assert
    expect(find.text('Please wait...'), findsOneWidget);
    expect(fakeRepository.changePasswordCallCount, 1);

    await tester.tap(find.byType(SolidButtonWithLoading), warnIfMissed: false);
    await tester.pump();

    expect(fakeRepository.changePasswordCallCount, 1);

    // Cleanup
    pendingOperation.complete();
    await tester.pumpAndSettle();
  });
}
