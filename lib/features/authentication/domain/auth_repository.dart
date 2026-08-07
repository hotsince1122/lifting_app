import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<void> reloadCurrentUser();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}
