import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_error_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_provider_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_identity_client.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

final class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._firebaseAuth, this._googleIdentityClient);

  final FirebaseAuth _firebaseAuth;
  final GoogleIdentityClient _googleIdentityClient;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _firebaseAuth.userChanges().map((user) {
      if (user == null) return null;

      return AuthUser(
        id: user.uid,
        email: user.email,
        isEmailVerified: user.emailVerified,
        providers: user.providerData
            .map((provider) => mapFirebaseAuthProviderId(provider.providerId))
            .whereType<AuthProviderType>()
            .toSet(),
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
    await Future.wait<void>([
      _runFirebaseAuthOperation(() => _firebaseAuth.signOut()),
      _googleIdentityClient.signOut(),
    ]);
  }

  @override
  Future<void> signInWithGoogle() async {
    final idToken = await _googleIdentityClient.requestIdToken();
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    await _runFirebaseAuthOperation(
      () => _firebaseAuth.signInWithCredential(credential),
    );
  }

  @override
  Future<void> linkGoogleProvider() async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw const AuthException(AuthErrorCode.noAuthenticatedUser);
    }

    final idToken = await _googleIdentityClient.requestIdToken();
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    await _runFirebaseAuthOperation(
      () => currentUser.linkWithCredential(credential),
    );
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
