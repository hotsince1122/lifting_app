import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/progress_protection_notice.dart';

import '../../test_doubles/fake_auth_repository.dart';

void main() {
  Future<void> pumpProgressProtectionNotice(
    WidgetTester tester, {
    required AuthUser? user,
  }) async {
    final fakeRepository = FakeAuthRepository(authState: Stream.value(user));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
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
}
