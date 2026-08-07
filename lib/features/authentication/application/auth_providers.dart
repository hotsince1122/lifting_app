import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/data/firebase_auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_repository.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebase = ref.watch(firebaseAuthProvider);

  return FirebaseAuthRepository(firebase);
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.watchAuthState();
});
