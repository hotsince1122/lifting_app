import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_sign_in_error_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

void main() {
  group('converts the auth google error to a local auth error', () {
    // Arrange
    const Map<GoogleSignInExceptionCode, AuthErrorCode>
    googleAuthErrorToLocalError = {
      GoogleSignInExceptionCode.canceled: AuthErrorCode.signInCanceled,
      GoogleSignInExceptionCode.clientConfigurationError:
          AuthErrorCode.identityProviderConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError:
          AuthErrorCode.identityProviderConfigurationError,
      GoogleSignInExceptionCode.uiUnavailable:
          AuthErrorCode.identityProviderUnavailable,
    };

    googleAuthErrorToLocalError.forEach((googleError, localError) {
      test('maps $googleError to $localError', () {
        // Act
        final result = mapGoogleSignInException(
          GoogleSignInException(code: googleError),
        );

        // Assert
        expect(result.code, localError);
      });
    });

    test('unknown errors', () {
      // Act
      final result = mapGoogleSignInException(
        GoogleSignInException(code: GoogleSignInExceptionCode.interrupted),
      );

      // Assert
      expect(result.code, AuthErrorCode.unknown);
    });
  });
}
