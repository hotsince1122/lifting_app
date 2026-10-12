import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_restore_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision_provider.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';

/// A deliberate selection made after the sign-in data decision is displayed.
enum SignInDataAction {
  attachLocal,
  keepLocal,
  transferLocal,
  restoreCloud,
  signOut,
}

enum SignInDataResolution {
  localAttached,
  localTransferred,
  restored,
  noBackup,
  signedOut,
}

final postSignInDataResolutionControllerProvider =
    AsyncNotifierProvider<
      PostSignInDataResolutionController,
      SignInDataResolution?
    >(PostSignInDataResolutionController.new);

class PostSignInDataResolutionController
    extends AsyncNotifier<SignInDataResolution?> {
  @override
  FutureOr<SignInDataResolution?> build() => null;

  Future<void> resolve({
    required String expectedUid,
    required SignInDataDecision expectedDecision,
    required SignInDataAction action,
  }) async {
    if (state.isLoading) return;

    state = const AsyncLoading<SignInDataResolution?>();
    final nextState = await AsyncValue.guard<SignInDataResolution?>(() async {
      if (expectedUid.trim().isEmpty) {
        throw ArgumentError.value(
          expectedUid,
          'expectedUid',
          'Cannot be empty.',
        );
      }

      await _requireCurrentUser(expectedUid);

      // Signing out never needs a cloud check and never changes local data.
      if (action == SignInDataAction.signOut) {
        if (expectedDecision != SignInDataDecision.chooseTransferOrSignOut) {
          throw StateError('Sign out is not valid for this data decision.');
        }
        await ref.read(authRepositoryProvider).signOut();
        return SignInDataResolution.signedOut;
      }

      // Re-read the sources instead of trusting a cached UI decision.
      final currentDecision = await _loadCurrentDecision(expectedUid);
      await _requireCurrentUser(expectedUid);
      if (currentDecision != expectedDecision) {
        throw const CloudBackupException(CloudBackupErrorCode.canceled);
      }
      _requireAllowedAction(currentDecision, action);

      final local = ref.read(localBackupRepositoryProvider);
      return switch (action) {
        SignInDataAction.attachLocal => _attachLocal(local, expectedUid),
        SignInDataAction.keepLocal => _keepLocal(
          local,
          expectedUid,
          currentDecision,
        ),
        SignInDataAction.transferLocal => _transferLocal(local, expectedUid),
        SignInDataAction.restoreCloud => _restoreCloud(),
        SignInDataAction.signOut => throw StateError('Already handled.'),
      };
    });

    if (ref.mounted) state = nextState;
  }

  Future<void> _requireCurrentUser(String expectedUid) async {
    if (!ref.mounted) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }
    final user = await ref.read(authStateProvider.future);
    if (user == null) {
      throw const CloudBackupException(CloudBackupErrorCode.unauthenticated);
    }
    if (user.id != expectedUid) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }
    if (!user.isEmailVerified) {
      throw const CloudBackupException(CloudBackupErrorCode.emailNotVerified);
    }
  }

  Future<SignInDataDecision> _loadCurrentDecision(String expectedUid) async {
    final local = ref.read(localBackupRepositoryProvider);
    final ownerUid = await local.loadOwnerUid();
    if (ownerUid == expectedUid) return SignInDataDecision.continueLocal;

    final hasLocalWorkouts = await local.hasWorkoutProgress();
    await _requireCurrentUser(expectedUid);
    final cloud = ref.read(cloudBackupRepositoryProvider);
    final metadata = await cloud
        .getBackupMetadata(userId: expectedUid)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw const CloudBackupException(
            CloudBackupErrorCode.retryLimitExceeded,
          ),
        );
    await _requireCurrentUser(expectedUid);

    return decideSignInData(
      signedInUid: expectedUid,
      ownerUid: ownerUid,
      hasLocalWorkouts: hasLocalWorkouts,
      hasCloudBackup: metadata != null,
    );
  }

  void _requireAllowedAction(
    SignInDataDecision decision,
    SignInDataAction action,
  ) {
    final allowed = switch (decision) {
      SignInDataDecision.attachLocal => action == SignInDataAction.attachLocal,
      SignInDataDecision.offerRestore ||
      SignInDataDecision.chooseLocalOrCloud =>
        action == SignInDataAction.keepLocal ||
            action == SignInDataAction.restoreCloud,
      SignInDataDecision.chooseTransferOrCloud =>
        action == SignInDataAction.transferLocal ||
            action == SignInDataAction.restoreCloud,
      SignInDataDecision.chooseTransferOrSignOut =>
        action == SignInDataAction.transferLocal,
      SignInDataDecision.continueLocal => false,
    };
    if (!allowed) {
      throw StateError('Action is not valid for this data decision.');
    }
  }

  Future<SignInDataResolution> _attachLocal(
    LocalBackupRepository local,
    String expectedUid,
  ) async {
    final ownerUid = await local.loadOwnerUid();
    await _requireCurrentUser(expectedUid);

    if (ownerUid == null) {
      await local.claimForUid(expectedUid);
    } else if (ownerUid != expectedUid) {
      await local.reassignOwnerUidIfNoWorkouts(
        expectedOwnerUid: ownerUid,
        newUid: expectedUid,
      );
    }

    ref.invalidate(postSignInDataAssessmentProvider);
    return SignInDataResolution.localAttached;
  }

  Future<SignInDataResolution> _keepLocal(
    LocalBackupRepository local,
    String expectedUid,
    SignInDataDecision decision,
  ) async {
    final ownerUid = await local.loadOwnerUid();
    await _requireCurrentUser(expectedUid);

    if (ownerUid == null) {
      await local.claimForUid(expectedUid);
    } else if (decision == SignInDataDecision.offerRestore &&
        ownerUid != expectedUid) {
      await local.reassignOwnerUidIfNoWorkouts(
        expectedOwnerUid: ownerUid,
        newUid: expectedUid,
      );
    } else {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }

    ref.invalidate(postSignInDataAssessmentProvider);
    return SignInDataResolution.localAttached;
  }

  Future<SignInDataResolution> _transferLocal(
    LocalBackupRepository local,
    String expectedUid,
  ) async {
    final ownerUid = await local.loadOwnerUid();
    await _requireCurrentUser(expectedUid);
    if (ownerUid == null || ownerUid == expectedUid) {
      throw const CloudBackupException(CloudBackupErrorCode.canceled);
    }

    // This method is reached only through an explicit transfer choice.
    await local.reassignOwnerUid(
      expectedOwnerUid: ownerUid,
      newUid: expectedUid,
    );
    ref.invalidate(postSignInDataAssessmentProvider);
    return SignInDataResolution.localTransferred;
  }

  Future<SignInDataResolution> _restoreCloud() async {
    final restoreController = ref.read(cloudRestoreControllerProvider.notifier);
    if (ref.read(cloudRestoreControllerProvider).isLoading) {
      throw StateError('A restore is already in progress.');
    }

    await restoreController.restoreNow();
    final restoreState = ref.read(cloudRestoreControllerProvider);
    if (restoreState.hasError) {
      Error.throwWithStackTrace(
        restoreState.error!,
        restoreState.stackTrace ?? StackTrace.current,
      );
    }

    ref.invalidate(postSignInDataAssessmentProvider);
    if (restoreState.value == RestoreResult.restored) {
      return SignInDataResolution.restored;
    }
    if (restoreState.value == RestoreResult.noBackup) {
      ref.invalidate(cloudBackupControllerProvider);
      return SignInDataResolution.noBackup;
    }
    throw StateError('Restore ended without a result.');
  }
}
