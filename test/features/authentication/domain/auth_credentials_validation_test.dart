import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';

void main() {
  group('validateEmail', () {
    test('returns emptyEmail for whitespace-only input', () {
      // Arrange
      const email = '    ';

      // Act
      final result = validateEmail(email);

      // Assert
      expect(result, AuthInputValidationError.emptyEmail);
    });

    test('returns null for a non-empty email', () {
      // Arrange
      const email = 'test@example.com';

      // Act
      final result = validateEmail(email);

      // Assert
      expect(result, isNull);
    });
  });

  group('normalizeEmail', () {
    test('returns normalized email', () {
      // Arrange
      const email = '   test@example.com    ';
      const expectedEmail = 'test@example.com';

      // Act
      final result = normalizeEmail(email);

      // Assert
      expect(result, expectedEmail);
    });
  });

  group('validatePassword', () {
    test('returns emptyPassword for a 0 character password', () {
      // Arrange
      const password = '';

      // Act
      final result = validatePassword(password);

      // Assert
      expect(result, AuthInputValidationError.emptyPassword);
    });

    test('returns null for a non empty password', () {
      // Arrange
      const password = 'goodPassword';

      // Act
      final result = validatePassword(password);

      // Assert
      expect(result, isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test(
      'returns emptyPasswordConfirmation when the password confirmation has 0 characters',
      () {
        // Arrange
        const password = 'goodPassword';
        const confirmation = '';

        // Act
        final result = validatePasswordConfirmation(
          password: password,
          confirmation: confirmation,
        );

        // Assert
        expect(result, AuthInputValidationError.emptyPasswordConfirmation);
      },
    );

    test(
      'returns passwordsDoNotMatch when password and confirmation do not match.',
      () {
        // Arrange
        const password = 'goodPassword';
        const confirmation = 'differentPassword';

        // Act
        final result = validatePasswordConfirmation(
          password: password,
          confirmation: confirmation,
        );

        // Assert
        expect(result, AuthInputValidationError.passwordsDoNotMatch);
      },
    );

    test('returns null when password and confirmation match.', () {
      // Arrange
      const password = 'goodPassword';
      const confirmation = 'goodPassword';

      // Act
      final result = validatePasswordConfirmation(
        password: password,
        confirmation: confirmation,
      );

      // Assert
      expect(result, isNull);
    });
  });
}
