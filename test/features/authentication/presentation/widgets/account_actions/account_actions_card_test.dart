import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/account_actions_card.dart';

import '../../../test_doubles/fake_auth_repository.dart';

void main() {
  Future<void> pumpAccountActionsCard(
    WidgetTester tester, {
    required AuthUser? user,
  }) async {
    final fakeRepository = FakeAuthRepository(authState: Stream.value(user));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: AccountActionsCard()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows the local-data warning for a guest', (tester) async {
    // Arrange + Act
    await pumpAccountActionsCard(tester, user: null);

    // Assert
    expect(find.textContaining('Without an account'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('shows all account actions for an email account', (tester) async {
    final user = AuthUser(
      id: 'user-123',
      email: 'alex@example.com',
      isEmailVerified: true,
      providers: {AuthProviderType.emailPassword},
    );

    await pumpAccountActionsCard(tester, user: user);

    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('hides change password for a Google-only account', (
    tester,
  ) async {
    final user = AuthUser(
      id: 'user-123',
      email: 'alex@example.com',
      isEmailVerified: true,
      providers: {AuthProviderType.google},
    );

    await pumpAccountActionsCard(tester, user: user);

    expect(find.text('Change password'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });
}
