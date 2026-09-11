import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';

void main() {
  Future<void> pumpFeedback(
    WidgetTester tester, {
    required AuthFeedbackFlow flow,
    AuthProviderType provider = AuthProviderType.emailPassword,
    AuthErrorCode? errorCode,
    bool isSuccess = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthenticationFeedback(
            errorCode: errorCode,
            provider: provider,
            flow: flow,
            isSuccess: isSuccess,
          ),
        ),
      ),
    );
  }

  final successMessages = <(AuthFeedbackFlow, String)>[
    (AuthFeedbackFlow.authentication, 'You’re signed in'),
    (AuthFeedbackFlow.passwordReset, 'Check your email'),
    (AuthFeedbackFlow.emailVerification, 'Verification email sent'),
    (AuthFeedbackFlow.changePassword, 'Password changed'),
  ];

  for (final (flow, title) in successMessages) {
    testWidgets('shows the success feedback for ${flow.name}', (tester) async {
      await pumpFeedback(tester, flow: flow, isSuccess: true);

      expect(find.text(title), findsOneWidget);
      expect(find.byType(SolidCard), findsOneWidget);
    });
  }

  testWidgets('an error takes precedence over success', (tester) async {
    await pumpFeedback(
      tester,
      flow: AuthFeedbackFlow.passwordReset,
      errorCode: AuthErrorCode.networkRequestFailed,
      isSuccess: true,
    );

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('keeps invalid password reset email on the field', (
    tester,
  ) async {
    await pumpFeedback(
      tester,
      flow: AuthFeedbackFlow.passwordReset,
      errorCode: AuthErrorCode.invalidEmail,
    );

    expect(find.byType(SolidCard), findsNothing);
  });

  testWidgets('uses a plain alert for password reset throttling', (
    tester,
  ) async {
    await pumpFeedback(
      tester,
      flow: AuthFeedbackFlow.passwordReset,
      errorCode: AuthErrorCode.tooManyRequests,
    );

    expect(
      find.text(
        'Too many reset attempts. Please wait a while before trying again.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SolidCard), findsNothing);
  });

  testWidgets('keeps the sign-in copy in the authentication flow', (
    tester,
  ) async {
    await pumpFeedback(
      tester,
      flow: AuthFeedbackFlow.authentication,
      errorCode: AuthErrorCode.invalidCredentials,
    );

    expect(find.text('Couldn’t sign in'), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets(
    'asks for a new session when password change needs recent login',
    (tester) async {
      await pumpFeedback(
        tester,
        flow: AuthFeedbackFlow.changePassword,
        errorCode: AuthErrorCode.requiresRecentLogin,
      );

      expect(find.text('Sign in again'), findsOneWidget);
      expect(find.byType(SolidCard), findsOneWidget);
    },
  );
}
