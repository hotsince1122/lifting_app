import 'package:google_sign_in/google_sign_in.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_identity_client.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_sign_in_error_mapper.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';

final class GoogleSignInClient implements GoogleIdentityClient {
  GoogleSignInClient(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  late final Future<void> _initialization = _googleSignIn.initialize();

  @override
  Future<String> requestIdToken() async {
    try {
      await _initialization;

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthException(AuthErrorCode.identityProviderUnavailable);
      }

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw const AuthException(AuthErrorCode.missingIdentityToken);
      }

      return idToken;
    } on GoogleSignInException catch (exception) {
      throw mapGoogleSignInException(exception);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _initialization;
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (exception) {
      throw mapGoogleSignInException(exception);
    }
  }
}
