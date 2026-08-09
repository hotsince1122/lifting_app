import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_identity_client.dart';
import 'package:lifting_tracker_app/features/authentication/data/google_sign_in_client.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);

final googleIdentityClientProvider = Provider<GoogleIdentityClient>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);

  return GoogleSignInClient(googleSignIn);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebase = ref.watch(firebaseAuthProvider);
  final googleIdentityClient = ref.watch(googleIdentityClientProvider);

  return FirebaseAuthRepository(firebase, googleIdentityClient);
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.watchAuthState();
});
