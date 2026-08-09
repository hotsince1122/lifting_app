import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required Set<AuthProviderType> providers,
  }) : providers = Set.unmodifiable(providers);

  final String id;
  final String? email;
  final bool isEmailVerified;
  final Set<AuthProviderType> providers;

  bool hasProvider(AuthProviderType provider) {
    return providers.contains(provider);
  }
}
