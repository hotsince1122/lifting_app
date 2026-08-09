import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Stream<AuthUser?>? authState,
    this.createAccountException,
    this.createAccountFuture,
    this.googleSignInException,
    this.googleSignInFuture,
  }) : _authState = authState ?? Stream<AuthUser?>.value(null);

  final Stream<AuthUser?> _authState;

  int createAccountCallCount = 0;
  String? lastCreateAccountEmail;
  String? lastCreateAccountPassword;
  final Future<void>? createAccountFuture;

  final Object? createAccountException;

  int signInCallCount = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;

  int passwordResetCallCount = 0;
  String? lastPasswordResetEmail;

  int emailVerificationCallCount = 0;
  int reloadCurrentUserCallCount = 0;
  int signOutCallCount = 0;

  int googleSignInCallCount = 0;
  int googleLinkCallCount = 0;

  final Object? googleSignInException;
  final Future<void>? googleSignInFuture;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _authState;
  }

  @override
  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createAccountCallCount++;
    lastCreateAccountEmail = email;
    lastCreateAccountPassword = password;

    final pendingFuture = createAccountFuture;
    if (pendingFuture != null) {
      await pendingFuture;
    }

    final exception = createAccountException;
    if (exception != null) {
      throw exception;
    }
  }

  @override
  Future<void> reloadCurrentUser() async {
    reloadCurrentUserCallCount++;
  }

  @override
  Future<void> sendEmailVerification() async {
    emailVerificationCallCount++;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCallCount++;
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastSignInEmail = email;
    lastSignInPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCallCount++;

    final pendingFuture = googleSignInFuture;
    if (pendingFuture != null) {
      await pendingFuture;
    }

    final exception = googleSignInException;
    if (exception != null) {
      throw exception;
    }
  }

  @override
  Future<void> linkGoogleProvider() async {
    googleLinkCallCount++;
  }
}
