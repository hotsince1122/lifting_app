import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> _runAuthOperation(
    Future<void> Function(AuthRepository repository) operation,
  ) async {
    if (state.isLoading) return;

    state = const AsyncLoading();

    state = await AsyncValue.guard<void>(() {
      final repository = ref.read(authRepositoryProvider);
      return operation(repository);
    });
  }

  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _runAuthOperation((repository) async {
      final validationError =
          validateEmail(email) ??
          validatePassword(password) ??
          validatePasswordConfirmation(
            password: password,
            confirmation: passwordConfirmation,
          );

      if (validationError != null) {
        throw AuthValidationException(validationError);
      }

      await repository.createAccountWithEmailAndPassword(
        email: normalizeEmail(email),
        password: password,
      );
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _runAuthOperation((repository) async {
      final validationError =
          validateEmail(email) ?? validatePassword(password);

      if (validationError != null) {
        throw AuthValidationException(validationError);
      }

      await repository.signInWithEmailAndPassword(
        email: normalizeEmail(email),
        password: password,
      );
    });
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _runAuthOperation((repository) async {
      final validationError = validateEmail(email);

      if (validationError != null) {
        throw AuthValidationException(validationError);
      }

      await repository.sendPasswordResetEmail(email: normalizeEmail(email));
    });
  }

  Future<void> sendEmailVerification() {
    return _runAuthOperation(
      (repository) => repository.sendEmailVerification(),
    );
  }

  Future<void> reloadCurrentUser() {
    return _runAuthOperation((repository) => repository.reloadCurrentUser());
  }

  Future<void> signOut() {
    return _runAuthOperation((repository) => repository.signOut());
  }
}
