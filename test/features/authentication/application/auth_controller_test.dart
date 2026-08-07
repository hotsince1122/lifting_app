import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

import '../test_doubles/fake_auth_repository.dart';

void main() {
  test(
    'normalizes email and preserves password when creating an account',
    () async {
      // Arrange
      final fakeRepository = FakeAuthRepository();
      final container = ProviderContainer.test(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );

      await container.read(authControllerProvider.future);

      const password = '   password with spaces   ';

      // Act
      await container
          .read(authControllerProvider.notifier)
          .createAccountWithEmailAndPassword(
            email: '   User@example.com   ',
            password: password,
            passwordConfirmation: password,
          );

      // Assert
      expect(fakeRepository.createAccountCallCount, 1);
      expect(fakeRepository.lastCreateAccountEmail, 'User@example.com');
      expect(fakeRepository.lastCreateAccountPassword, password);
      expect(container.read(authControllerProvider).hasValue, isTrue);
    },
  );

  test('returns error if the email is empty', () async {
    // Arrange
    final fakeRepository = FakeAuthRepository();
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);

    // Act
    await container
        .read(authControllerProvider.notifier)
        .createAccountWithEmailAndPassword(
          email: '   ',
          password: 'goodPassword',
          passwordConfirmation: 'goodPassword',
        );

    final state = container.read(authControllerProvider);

    // Assert
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthValidationException>());

    final validationException = state.error! as AuthValidationException;
    expect(validationException.error, AuthInputValidationError.emptyEmail);

    expect(fakeRepository.createAccountCallCount, 0);
  });

  test('preserves a repository error when account creation fails', () async {
    // Arrange
    const expectedException = AuthException(AuthErrorCode.networkRequestFailed);

    final fakeRepository = FakeAuthRepository(
      createAccountException: expectedException,
    );

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);

    // Act
    await container
        .read(authControllerProvider.notifier)
        .createAccountWithEmailAndPassword(
          email: 'user@example.com',
          password: 'goodPassword',
          passwordConfirmation: 'goodPassword',
        );

    final state = container.read(authControllerProvider);

    // Assert
    expect(state.hasError, isTrue);
    expect(state.error, same(expectedException));
    expect(fakeRepository.createAccountCallCount, 1);
  });

  test(
    'ignores a second account creation while the first is loading',
    () async {
      // Arrange
      final completer = Completer<void>();
      final fakeRepository = FakeAuthRepository(
        createAccountFuture: completer.future,
      );

      final container = ProviderContainer.test(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );

      await container.read(authControllerProvider.future);
      final controller = container.read(authControllerProvider.notifier);

      // Act
      final firstCall = controller.createAccountWithEmailAndPassword(
        email: 'user@example.com',
        password: 'goodPassword',
        passwordConfirmation: 'goodPassword',
      );

      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).isLoading, isTrue);

      await controller.createAccountWithEmailAndPassword(
        email: 'another@example.com',
        password: 'anotherPassword',
        passwordConfirmation: 'anotherPassword',
      );

      // Assert: second call did not make it to Firebase
      expect(fakeRepository.createAccountCallCount, 1);

      // Firebase response simulation
      completer.complete();
      await firstCall;

      expect(container.read(authControllerProvider).hasValue, isTrue);
    },
  );

  test('sign in normalizes email and preserves password', () async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);

    const email = '   user@example.com   ';
    const password = 'goodPassword';

    // Act
    await controller.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Assert
    expect(fakeRepository.signInCallCount, 1);
    expect(fakeRepository.lastSignInEmail, 'user@example.com');
    expect(fakeRepository.lastSignInPassword, 'goodPassword');
  });

  test('password reset normalizes email', () async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);

    const email = '   user@example.com   ';

    // Act
    await controller.sendPasswordResetEmail(email: email);

    // Assert
    expect(fakeRepository.passwordResetCallCount, 1);
    expect(fakeRepository.lastPasswordResetEmail, 'user@example.com');
  });

  test('password reset rejects an empty email', () async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);

    const email = '   ';

    // Act
    await controller.sendPasswordResetEmail(email: email);

    final state = container.read(authControllerProvider);

    // Assert
    expect(state.error, isA<AuthValidationException>());
    expect(fakeRepository.passwordResetCallCount, 0);

    final validationException = state.error! as AuthValidationException;
    expect(validationException.error, AuthInputValidationError.emptyEmail);
  });

  test('delegates verification reload and sign out', () async {
    // Arrange
    final fakeRepository = FakeAuthRepository();

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);

    // Act
    await controller.sendEmailVerification();
    await controller.reloadCurrentUser();
    await controller.signOut();

    // Assert
    expect(fakeRepository.emailVerificationCallCount, 1);
    expect(fakeRepository.reloadCurrentUserCallCount, 1);
    expect(fakeRepository.signOutCallCount, 1);
  });
}
