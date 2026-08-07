enum AuthInputValidationError {
  emptyEmail,
  emptyPassword,
  emptyPasswordConfirmation,
  passwordsDoNotMatch,
}

String normalizeEmail(String email) => email.trim();

AuthInputValidationError? validateEmail(String email) {
  return normalizeEmail(email).isEmpty
      ? AuthInputValidationError.emptyEmail
      : null;
}

AuthInputValidationError? validatePassword(String password) {
  return password.isEmpty ? AuthInputValidationError.emptyPassword : null;
}

AuthInputValidationError? validatePasswordConfirmation({
  required String password,
  required String confirmation,
}) {
  if (confirmation.isEmpty) {
    return AuthInputValidationError.emptyPasswordConfirmation;
  }

  if (password != confirmation) {
    return AuthInputValidationError.passwordsDoNotMatch;
  }

  return null;
}

final class AuthValidationException implements Exception {
  const AuthValidationException(this.error);

  final AuthInputValidationError error;
}
