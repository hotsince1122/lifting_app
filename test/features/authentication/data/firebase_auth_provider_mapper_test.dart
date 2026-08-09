import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_provider_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';

void main() {
  group('maps Firebase provider IDs', () {
    // Arrange
    const knownProviders = <String, AuthProviderType>{
      'password': AuthProviderType.emailPassword,
      'google.com': AuthProviderType.google,
    };

    knownProviders.forEach((firebaseProviderId, authProviderType) {
      test('maps $firebaseProviderId to $authProviderType', () {
        // Act
        final result = mapFirebaseAuthProviderId(firebaseProviderId);

        // Assert
        expect(result, authProviderType);
      });
    });

    test('returns null for an unknown Firebase provider ID', () {
      // Act
      final result = mapFirebaseAuthProviderId('unknown-provider');

      // Assert
      expect(result, isNull);
    });
  });
}
