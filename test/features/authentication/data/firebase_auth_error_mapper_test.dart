import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_error_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

void main() {
  group('converts the auth firebase error to a local auth error', () {
    // Arrange
    const Map<String, AuthErrorCode> firebaseErrorToLocalErrorMap = {
      'invalid-email': AuthErrorCode.invalidEmail,
      'weak-password': AuthErrorCode.weakPassword,
      'email-already-in-use': AuthErrorCode.emailAlreadyInUse,
      'invalid-credential': AuthErrorCode.invalidCredentials,
      'wrong-password': AuthErrorCode.invalidCredentials,
      'user-not-found': AuthErrorCode.invalidCredentials,
      'user-disabled': AuthErrorCode.userDisabled,
      'too-many-requests': AuthErrorCode.tooManyRequests,
      'network-request-failed': AuthErrorCode.networkRequestFailed,
      'operation-not-allowed': AuthErrorCode.operationNotAllowed,
      'provider-already-linked': AuthErrorCode.providerAlreadyLinked,
      'credential-already-in-use': AuthErrorCode.credentialAlreadyInUse,
      'account-exists-with-different-credential':
          AuthErrorCode.accountExistsWithDifferentCredential,
    };

    firebaseErrorToLocalErrorMap.forEach((firebaseError, errorCode) {
      test('maps $firebaseError to $errorCode', () {
        // Act
        final result = mapFirebaseAuthException(
          FirebaseAuthException(code: firebaseError),
        );

        // Assert
        expect(result.code, errorCode);
      });
    });
  });

  test('unknown errors', () {
    // Arrange
    final FirebaseAuthException firebaseException = FirebaseAuthException(
      code: 'unknown-error',
    );

    // Act
    final result = mapFirebaseAuthException(firebaseException);

    // Assert
    expect(result.code, AuthErrorCode.unknown);
  });
}
