import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/pages/email_authentication_page.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_auth_text_field.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/solid_button_with_loading.dart';

import '../../test_doubles/fake_auth_repository.dart';

void main() {
  Future<void> pumpEmailAuthenticationPage(
    WidgetTester tester,
    FakeAuthRepository fakeRepository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const EmailAuthenticationPage(),
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

  testWidgets('shows required errors and does not create an account', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    await pumpEmailAuthenticationPage(tester, fakeRepository);

    // Act
    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Create account'),
    );
    await tester.pump();

    // Assert
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);

    expect(fakeRepository.createAccountCallCount, 0);
  });

  testWidgets('rejects different password and confirmation values', (
    tester,
  ) async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    await pumpEmailAuthenticationPage(tester, fakeRepository);

    // Act
    await tester.enterText(fieldWithTitle('Email'), 'alex@example.com');
    await tester.enterText(fieldWithTitle('Password'), 'password-123');
    await tester.enterText(
      fieldWithTitle('Confirm password'),
      'different-password',
    );

    await tester.tap(
      find.widgetWithText(SolidButtonWithLoading, 'Create account'),
    );
    await tester.pump();

    // Assert
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(fakeRepository.createAccountCallCount, 0);
  });

  testWidgets('hides password confirmation when sign in is selected', (
    tester,
  ) async {
    final fakeRepository = FakeAuthRepository();

    await pumpEmailAuthenticationPage(tester, fakeRepository);

    expect(find.text('Confirm password'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm password'), findsNothing);
    expect(
      find.widgetWithText(SolidButtonWithLoading, 'Sign in'),
      findsOneWidget,
    );
  });

  testWidgets('shows loading and ignores a second account creation submit', (
    tester,
  ) async {
    // Arrange
    final pendingOperation = Completer<void>();

    final fakeRepository = FakeAuthRepository(
      createAccountFuture: pendingOperation.future,
    );

    await pumpEmailAuthenticationPage(tester, fakeRepository);

    await tester.enterText(fieldWithTitle('Email'), 'alex@example.com');
    await tester.enterText(fieldWithTitle('Password'), 'password-123');
    await tester.enterText(fieldWithTitle('Confirm password'), 'password-123');

    // Act: pornim operația, dar nu completăm Future-ul.
    await tester.tap(find.byType(SolidButtonWithLoading));
    await tester.pump();

    // Assert: UI-ul este în loading.
    expect(find.text('Please wait...'), findsOneWidget);
    expect(fakeRepository.createAccountCallCount, 1);

    // Încercăm să apăsăm din nou în timpul loading-ului.
    await tester.tap(find.byType(SolidButtonWithLoading));
    await tester.pump();

    expect(fakeRepository.createAccountCallCount, 1);

    // Cleanup: permitem operației să se termine.
    pendingOperation.complete();
    await tester.pumpAndSettle();
  });
}
