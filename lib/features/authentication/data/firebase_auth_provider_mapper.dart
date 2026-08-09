import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';

AuthProviderType? mapFirebaseAuthProviderId(String providerId) {
  return switch (providerId) {
    'password' => AuthProviderType.emailPassword,
    'google.com' => AuthProviderType.google,
    _ => null,
  };
}
