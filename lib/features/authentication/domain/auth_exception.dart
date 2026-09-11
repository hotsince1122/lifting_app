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
  requiresRecentLogin,
  unknown,
  signInCanceled,
  identityProviderConfigurationError,
  identityProviderUnavailable,
  missingIdentityToken,
  providerAlreadyLinked,
  credentialAlreadyInUse,
  accountExistsWithDifferentCredential,
}

final class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;
}
