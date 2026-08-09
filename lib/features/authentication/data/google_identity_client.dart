abstract interface class GoogleIdentityClient {
  Future<String> requestIdToken();

  Future<void> signOut();
}
