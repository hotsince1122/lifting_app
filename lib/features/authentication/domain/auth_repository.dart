import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();
}
