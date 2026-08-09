import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

AuthException mapFirebaseAuthException(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'invalid-email':
      return AuthException(AuthErrorCode.invalidEmail);
    case 'weak-password':
      return AuthException(AuthErrorCode.weakPassword);
    case 'email-already-in-use':
      return AuthException(AuthErrorCode.emailAlreadyInUse);
    case 'invalid-credential':
      return AuthException(AuthErrorCode.invalidCredentials);
    case 'wrong-password':
      return AuthException(AuthErrorCode.invalidCredentials);
    case 'user-not-found':
      return AuthException(AuthErrorCode.invalidCredentials);
    case 'user-disabled':
      return AuthException(AuthErrorCode.userDisabled);
    case 'too-many-requests':
      return AuthException(AuthErrorCode.tooManyRequests);
    case 'network-request-failed':
      return AuthException(AuthErrorCode.networkRequestFailed);
    case 'operation-not-allowed':
      return AuthException(AuthErrorCode.operationNotAllowed);
    case 'provider-already-linked':
      return AuthException(AuthErrorCode.providerAlreadyLinked);
    case 'credential-already-in-use':
      return AuthException(AuthErrorCode.credentialAlreadyInUse);
    case 'account-exists-with-different-credential':
      return AuthException(AuthErrorCode.accountExistsWithDifferentCredential);
    default:
      return AuthException(AuthErrorCode.unknown);
  }
}
