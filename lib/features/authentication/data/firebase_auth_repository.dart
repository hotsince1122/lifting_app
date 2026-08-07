import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

final class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _firebaseAuth.userChanges().map((user) {
      if (user == null) return null;

      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
    });
  }
}
