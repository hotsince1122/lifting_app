import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

import '../test_doubles/fake_auth_repository.dart';

void main() {
  test('exposes the user emitted by the auth repo.', () async {
    // Arrange
    final expectedUser = AuthUser(
      id: 'user-123',
      email: 'test@example.com',
      isEmailVerified: true,
    );

    final fakeRepo = FakeAuthRepository(authState: Stream.value(expectedUser));

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );

    container.listen(authStateProvider, (_, _) {});

    // Act
    final actualUser = await container.read(authStateProvider.future);

    // Assert
    expect(actualUser, same(expectedUser));
  });

  test('exposes null when the auth repo reports signed out.', () async {
    // Arrange
    final fakeRepo = FakeAuthRepository(authState: Stream.value(null));

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );

    container.listen(authStateProvider, (_, _) {});

    // Act
    final actualUser = await container.read(authStateProvider.future);

    // Assert
    expect(actualUser, isNull);
  });
}
