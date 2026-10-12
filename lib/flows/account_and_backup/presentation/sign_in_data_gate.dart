import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_decision_provider.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/post_sign_in_data_resolution_controller.dart';

class SignInDataGate extends ConsumerStatefulWidget {
  const SignInDataGate({required this.child, super.key});

  final Widget child;

  static bool isLoading(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_SignInDataGateStatus>()
          ?.isLoading ??
      false;

  @override
  ConsumerState<SignInDataGate> createState() => _SignInDataGateState();
}

class _SignInDataGateState extends ConsumerState<SignInDataGate> {
  String? _observedUid;
  String? _automaticAttemptUid;
  String? _operationUid;

  void _resolve(
    String uid,
    SignInDataDecision decision,
    SignInDataAction action,
  ) {
    _operationUid = uid;
    unawaited(
      ref
          .read(postSignInDataResolutionControllerProvider.notifier)
          .resolve(
            expectedUid: uid,
            expectedDecision: decision,
            action: action,
          ),
    );
  }

  void _attachAutomatically(String uid) {
    if (_automaticAttemptUid == uid) return;
    _automaticAttemptUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser?.id != uid || !currentUser!.isEmailVerified) return;
      _resolve(
        uid,
        SignInDataDecision.attachLocal,
        SignInDataAction.attachLocal,
      );
    });
  }

  void _retry({bool authOnly = false}) {
    setState(() {
      _automaticAttemptUid = null;
      _operationUid = null;
    });
    if (authOnly) {
      ref.invalidate(authStateProvider);
    } else {
      ref.invalidate(cloudBackupControllerProvider);
      ref.invalidate(postSignInDataAssessmentProvider);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final resolution = ref.watch(postSignInDataResolutionControllerProvider);
    final authOperation = ref.watch(authControllerProvider);
    var loading = false;

    final overlay = auth.when<Widget?>(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () {
        loading = true;
        return null;
      },
      error: (_, _) => _error(
        title: 'Could not check your account',
        message: 'Check your connection and try again.',
        canSignOut: false,
        signingOut: authOperation.isLoading,
        retryAuthOnly: true,
      ),
      data: (user) {
        if (_observedUid != user?.id) {
          _observedUid = user?.id;
          _automaticAttemptUid = null;
          _operationUid = null;
        }
        if (user == null || !user.isEmailVerified) return null;

        final assessmentState = ref.watch(postSignInDataAssessmentProvider);
        return assessmentState.when<Widget?>(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () {
            loading = true;
            return null;
          },
          error: (_, _) => _error(
            title: 'Could not check your backup',
            message:
                'Your local data is safe. Check your connection and try again.',
            canSignOut: true,
            signingOut: authOperation.isLoading,
            signOutFailed: authOperation.hasError,
          ),
          data: (assessment) {
            if (assessment == null || assessment.uid != user.id) {
              loading = true;
              return null;
            }
            if (assessment.decision == SignInDataDecision.continueLocal) {
              return null;
            }

            if (resolution.isLoading) {
              loading = true;
              return null;
            }
            if (resolution.hasError && _operationUid == user.id) {
              return _error(
                title: 'Could not apply your choice',
                message:
                    'Your data has not been replaced. Check the account and try again.',
                canSignOut: true,
                signingOut: authOperation.isLoading,
                signOutFailed: authOperation.hasError,
              );
            }

            if (assessment.decision == SignInDataDecision.attachLocal) {
              _attachAutomatically(user.id);
              loading = true;
              return null;
            }

            return _choice(
              uid: user.id,
              decision: assessment.decision,
              noBackup:
                  _operationUid == user.id &&
                  resolution.value == SignInDataResolution.noBackup,
            );
          },
        );
      },
    );

    return _SignInDataGateStatus(
      isLoading: loading,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (loading)
            const ModalBarrier(color: Colors.transparent, dismissible: false),
          if (overlay != null) ...[
            const ModalBarrier(color: Colors.black54, dismissible: false),
            BlockSemantics(
              child: SafeArea(child: Center(child: overlay)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _error({
    required String title,
    required String message,
    required bool canSignOut,
    required bool signingOut,
    bool signOutFailed = false,
    bool retryAuthOnly = false,
  }) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(
        signOutFailed ? 'Could not sign out. Please try again.' : message,
      ),
      actions: [
        if (canSignOut)
          CupertinoDialogAction(
            onPressed: signingOut ? null : _signOut,
            child: const Text('Sign out'),
          ),
        CupertinoDialogAction(
          onPressed: signingOut ? null : () => _retry(authOnly: retryAuthOnly),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _choice({
    required String uid,
    required SignInDataDecision decision,
    required bool noBackup,
  }) {
    final prompt = _promptFor(decision);
    return CupertinoAlertDialog(
      title: Text(prompt.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prompt.message),
          if (noBackup) ...[
            const SizedBox(height: 8),
            const Text('That cloud backup is no longer available.'),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => _resolve(uid, decision, prompt.secondaryAction),
          child: Text(prompt.secondaryLabel),
        ),
        CupertinoDialogAction(
          onPressed: () => _resolve(uid, decision, prompt.primaryAction),
          child: Text(prompt.primaryLabel),
        ),
      ],
    );
  }
}

class _SignInDataGateStatus extends InheritedWidget {
  const _SignInDataGateStatus({required this.isLoading, required super.child});

  final bool isLoading;

  @override
  bool updateShouldNotify(_SignInDataGateStatus oldWidget) =>
      isLoading != oldWidget.isLoading;
}

final class _SignInDataPrompt {
  const _SignInDataPrompt({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final SignInDataAction primaryAction;
  final String secondaryLabel;
  final SignInDataAction secondaryAction;
}

_SignInDataPrompt _promptFor(SignInDataDecision decision) => switch (decision) {
  SignInDataDecision.offerRestore => const _SignInDataPrompt(
    title: 'Cloud backup available',
    message:
        "Restore the cloud backup to replace this device's data, or keep the local data. Keeping it won't change the backup.",
    primaryLabel: 'Restore backup',
    primaryAction: SignInDataAction.restoreCloud,
    secondaryLabel: 'Keep local data',
    secondaryAction: SignInDataAction.keepLocal,
  ),
  SignInDataDecision.chooseLocalOrCloud => const _SignInDataPrompt(
    title: 'Choose your workout data',
    message:
        "Restore to replace this device's plans, workouts, and history. Keep local data to leave the cloud backup unchanged.",
    primaryLabel: 'Restore backup',
    primaryAction: SignInDataAction.restoreCloud,
    secondaryLabel: 'Keep local data',
    secondaryAction: SignInDataAction.keepLocal,
  ),
  SignInDataDecision.chooseTransferOrCloud => const _SignInDataPrompt(
    title: 'Workouts from another account',
    message:
        "These workouts belong to another account. Use them here, or restore this account's backup to replace this device's data.",
    primaryLabel: 'Restore backup',
    primaryAction: SignInDataAction.restoreCloud,
    secondaryLabel: 'Use local workouts',
    secondaryAction: SignInDataAction.transferLocal,
  ),
  SignInDataDecision.chooseTransferOrSignOut => const _SignInDataPrompt(
    title: 'Workouts from another account',
    message:
        'These workouts belong to another account. This account has no cloud backup. Use them here, or sign out.',
    primaryLabel: 'Use local workouts',
    primaryAction: SignInDataAction.transferLocal,
    secondaryLabel: 'Sign out',
    secondaryAction: SignInDataAction.signOut,
  ),
  SignInDataDecision.continueLocal || SignInDataDecision.attachLocal =>
    throw StateError('This decision does not need a choice.'),
};
