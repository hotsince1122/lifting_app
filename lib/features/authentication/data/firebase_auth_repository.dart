import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_error_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
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

  @override
  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _runFirebaseAuthOperation(
      () => _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _runFirebaseAuthOperation(
      () => _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw const AuthException(AuthErrorCode.noAuthenticatedUser);
    }

    await _runFirebaseAuthOperation(() => currentUser.sendEmailVerification());
  }

  @override
  Future<void> reloadCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw const AuthException(AuthErrorCode.noAuthenticatedUser);
    }

    await _runFirebaseAuthOperation(() => currentUser.reload());
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _runFirebaseAuthOperation(
      () => _firebaseAuth.sendPasswordResetEmail(email: email),
    );
  }

  @override
  Future<void> signOut() async {
    await _runFirebaseAuthOperation(() => _firebaseAuth.signOut());
  }
}

Future<T> _runFirebaseAuthOperation<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return result;
  } on FirebaseAuthException catch (exception) {
    throw mapFirebaseAuthException(exception);
  }
}
