import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum AuthFeedbackFlow {
  authentication,
  passwordReset,
  emailVerification,
  changePassword,
}

class AuthenticationFeedback extends StatelessWidget {
  const AuthenticationFeedback({
    required this.errorCode,
    required this.provider,
    required this.flow,
    this.isSuccess = false,
    super.key,
  });

  final AuthErrorCode? errorCode;
  final AuthProviderType provider;
  final AuthFeedbackFlow flow;
  final bool isSuccess;

  Widget importantError(String title, String body, BuildContext context) {
    return SolidCard(
      color: Colors.red.withValues(alpha: 0.12),
      borderColor: Colors.red.withValues(alpha: 0.48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIcons.warning(), size: 16, color: Colors.red),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  body,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget importantSuccess(String title, String body, BuildContext context) {
    return SolidCard(
      color: AppColors.primary.withValues(alpha: 0.12),
      borderColor: AppColors.primary.withValues(alpha: 0.48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIcons.check(), size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  body,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget alert(String body, BuildContext context) {
    return Text(
      body,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
    );
  }

  Widget? successFeedback(BuildContext context) {
    if (!isSuccess) return null;

    return switch (flow) {
      AuthFeedbackFlow.authentication => importantSuccess(
        'You’re signed in',
        'Your account is ready and your progress can now be protected in the cloud.',
        context,
      ),
      AuthFeedbackFlow.passwordReset => importantSuccess(
        'Check your email',
        'If an account exists for this email, you’ll receive a password reset link shortly.',
        context,
      ),
      AuthFeedbackFlow.emailVerification => importantSuccess(
        'Verification email sent',
        'Check your inbox and follow the link to verify your email address.',
        context,
      ),
      AuthFeedbackFlow.changePassword => importantSuccess(
        'Password changed',
        'Your password was updated successfully.',
        context,
      ),
    };
  }

  Widget? errorFeedback(BuildContext context) {
    return switch ((flow, provider, errorCode)) {
      (_, _, null) => null,

      (_, _, AuthErrorCode.networkRequestFailed) => importantError(
        'No connection',
        'Check your internet connection and try again.',
        context,
      ),

      (AuthFeedbackFlow.passwordReset, _, AuthErrorCode.invalidEmail) => null,

      (AuthFeedbackFlow.passwordReset, _, AuthErrorCode.invalidCredentials) =>
        importantSuccess(
          'Check your email',
          'If an account exists for this email, you’ll receive a password reset link shortly.',
          context,
        ),

      (AuthFeedbackFlow.passwordReset, _, AuthErrorCode.tooManyRequests) =>
        alert(
          'Too many reset attempts. Please wait a while before trying again.',
          context,
        ),

      (AuthFeedbackFlow.passwordReset, _, AuthErrorCode.operationNotAllowed) =>
        alert(
          'Password reset isn’t available right now. Please try again later.',
          context,
        ),

      (AuthFeedbackFlow.passwordReset, _, _) => alert(
        'We couldn’t send the reset link. Please try again later.',
        context,
      ),

      (
        AuthFeedbackFlow.emailVerification,
        _,
        AuthErrorCode.noAuthenticatedUser,
      ) =>
        importantError(
          'Sign in required',
          'Sign in before requesting another verification email.',
          context,
        ),

      (AuthFeedbackFlow.emailVerification, _, AuthErrorCode.tooManyRequests) =>
        alert(
          'Too many verification requests. Please wait a while before trying again.',
          context,
        ),

      (
        AuthFeedbackFlow.emailVerification,
        _,
        AuthErrorCode.operationNotAllowed,
      ) =>
        alert(
          'Email verification isn’t available right now. Please try again later.',
          context,
        ),

      (AuthFeedbackFlow.emailVerification, _, _) => alert(
        'We couldn’t send the verification email. Please try again.',
        context,
      ),

      (
        AuthFeedbackFlow.changePassword,
        _,
        AuthErrorCode.invalidEmail ||
            AuthErrorCode.invalidCredentials ||
            AuthErrorCode.weakPassword,
      ) =>
        null,

      (
        AuthFeedbackFlow.changePassword,
        _,
        AuthErrorCode.noAuthenticatedUser || AuthErrorCode.userDisabled,
      ) =>
        importantError(
          'Account unavailable',
          'Sign in again before changing your password.',
          context,
        ),

      (AuthFeedbackFlow.changePassword, _, AuthErrorCode.requiresRecentLogin) =>
        importantError(
          'Sign in again',
          'We couldn’t confirm your session. Sign out, sign in again, then retry.',
          context,
        ),

      (AuthFeedbackFlow.changePassword, _, AuthErrorCode.tooManyRequests) =>
        alert(
          'Too many attempts. Please wait a while before trying again.',
          context,
        ),

      (AuthFeedbackFlow.changePassword, _, _) => alert(
        'We couldn’t change your password. Please try again.',
        context,
      ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.emailPassword,
        AuthErrorCode.invalidEmail ||
            AuthErrorCode.weakPassword ||
            AuthErrorCode.emailAlreadyInUse,
      ) =>
        null,

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.google,
        AuthErrorCode.signInCanceled,
      ) =>
        alert(
          'Google sign-in was cancelled. You can try again or use email.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.emailPassword,
        AuthErrorCode.invalidCredentials,
      ) =>
        importantError(
          'Couldn’t sign in',
          'Email or password is incorrect.',
          context,
        ),

      (AuthFeedbackFlow.authentication, _, AuthErrorCode.tooManyRequests) =>
        importantError(
          'Too many attempts',
          'Please wait a while before trying again.',
          context,
        ),

      (AuthFeedbackFlow.authentication, _, AuthErrorCode.userDisabled) =>
        importantError(
          'Account unavailable',
          'This account has been disabled. Please contact support if you think this is a mistake.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.google,
        AuthErrorCode.accountExistsWithDifferentCredential,
      ) =>
        importantError(
          'Account already exists',
          'This email is already associated with another sign-in method. Sign in using that method, then connect Google from Account & Backup.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.google,
        AuthErrorCode.identityProviderUnavailable ||
            AuthErrorCode.identityProviderConfigurationError ||
            AuthErrorCode.missingIdentityToken ||
            AuthErrorCode.operationNotAllowed,
      ) =>
        importantError(
          'Google sign-in is unavailable',
          'Please try again later or continue with email.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.google,
        AuthErrorCode.providerAlreadyLinked,
      ) =>
        importantError(
          'Google is already connected',
          'This account already uses Google as a sign-in method.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.google,
        AuthErrorCode.credentialAlreadyInUse,
      ) =>
        importantError(
          'Google account already in use',
          'This Google account is already connected to another account.',
          context,
        ),

      (
        AuthFeedbackFlow.authentication,
        AuthProviderType.emailPassword,
        AuthErrorCode.operationNotAllowed,
      ) =>
        importantError(
          'Email authentication is unavailable',
          'Email and password authentication isn’t available right now. Please try again later.',
          context,
        ),

      (AuthFeedbackFlow.authentication, AuthProviderType.google, _) =>
        importantError(
          'Google sign-in is unavailable',
          'We couldn’t sign you in with Google right now. Please try again or continue with email.',
          context,
        ),

      (AuthFeedbackFlow.authentication, AuthProviderType.emailPassword, _) =>
        importantError(
          'Something went wrong',
          'We couldn’t complete the request. Please try again.',
          context,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final feedback = errorCode == null
        ? successFeedback(context)
        : errorFeedback(context);

    if (feedback == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsGeometry.only(top: AppSpacing.s12),
      child: feedback,
    );
  }
}
