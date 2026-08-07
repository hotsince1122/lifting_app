enum AuthErrorCode {
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  invalidCredentials,
  userDisabled,
  tooManyRequests,
  networkRequestFailed,
  operationNotAllowed,
  noAuthenticatedUser,
  unknown,
}

final class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;
}
