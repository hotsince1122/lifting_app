import 'package:google_sign_in/google_sign_in.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

AuthException mapGoogleSignInException(GoogleSignInException exception) {
  return switch (exception.code) {
    GoogleSignInExceptionCode.canceled => const AuthException(
      AuthErrorCode.signInCanceled,
    ),
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError => const AuthException(
      AuthErrorCode.identityProviderConfigurationError,
    ),
    GoogleSignInExceptionCode.uiUnavailable => const AuthException(
      AuthErrorCode.identityProviderUnavailable,
    ),
    _ => const AuthException(AuthErrorCode.unknown),
  };
}