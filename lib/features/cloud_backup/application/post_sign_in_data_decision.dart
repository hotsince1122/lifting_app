enum SignInDataDecision {
  continueLocal,
  attachLocal,
  offerRestore,
  chooseLocalOrCloud,
  chooseTransferOrCloud,
  chooseTransferOrSignOut,
}

SignInDataDecision decideSignInData({
  required String signedInUid,
  required String? ownerUid,
  required bool hasLocalWorkouts,
  required bool hasCloudBackup,
}) {
  if (ownerUid == signedInUid) {
    return SignInDataDecision.continueLocal;
  }

  if (!hasLocalWorkouts) {
    return hasCloudBackup
        ? SignInDataDecision.offerRestore
        : SignInDataDecision.attachLocal;
  }

  if (ownerUid == null) {
    return hasCloudBackup
        ? SignInDataDecision.chooseLocalOrCloud
        : SignInDataDecision.attachLocal;
  }

  return hasCloudBackup
      ? SignInDataDecision.chooseTransferOrCloud
      : SignInDataDecision.chooseTransferOrSignOut;
}
