import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

final class SignInDataAssessment {
  const SignInDataAssessment({required this.uid, required this.decision});

  final String uid;
  final SignInDataDecision decision;
}

final postSignInDataAssessmentProvider = FutureProvider<SignInDataAssessment?>((
  ref,
) async {
  final user = await ref.watch(authStateProvider.future);

  if (user == null || !user.isEmailVerified) {
    return null;
  }

  final backupRepository = ref.read(localBackupRepositoryProvider);

  final ownerUid = await backupRepository.loadOwnerUid();

  if (ownerUid == user.id) {
    return SignInDataAssessment(
      uid: user.id,
      decision: SignInDataDecision.continueLocal,
    );
  }

  final hasLocalWorkouts = await backupRepository.hasWorkoutProgress();

  final metadata = await ref.read(cloudBackupControllerProvider.future);

  if (!ref.mounted) {
    throw const CloudBackupException(CloudBackupErrorCode.canceled);
  }
  final currentUser = await ref.read(authStateProvider.future);
  if (currentUser == null ||
      currentUser.id != user.id ||
      !currentUser.isEmailVerified) {
    throw const CloudBackupException(CloudBackupErrorCode.canceled);
  }

  return SignInDataAssessment(
    uid: user.id,
    decision: decideSignInData(
      signedInUid: user.id,
      ownerUid: ownerUid,
      hasLocalWorkouts: hasLocalWorkouts,
      hasCloudBackup: metadata != null,
    ),
  );
});

final postSignInDataDecisionProvider = FutureProvider<SignInDataDecision?>((
  ref,
) async {
  final assessment = await ref.watch(postSignInDataAssessmentProvider.future);
  return assessment?.decision;
});
