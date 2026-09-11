import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/solid_button_with_loading.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/verify_email/email_verification_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/verify_email/verification_notice.dart';

class VerifyEmailActions extends ConsumerStatefulWidget {
  const VerifyEmailActions({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailActions> createState() => _VerifyEmailSectionState();
}

class _VerifyEmailSectionState extends ConsumerState<VerifyEmailActions> {
  VerificationNotice notice = VerificationNotice.none;

  Future<void> checkEmailVerification() async {
    setState(() {
      notice = VerificationNotice.none;
    });

    await ref.read(authControllerProvider.notifier).reloadCurrentUser();

    if (!mounted || ref.read(authControllerProvider).hasError) return;

    final user = await ref.refresh(authStateProvider.future);

    if (!mounted) return;

    setState(() {
      if (user?.isEmailVerified == false) {
        notice = VerificationNotice.notVerified;
      }
    });
  }

  Future<void> resendVerificationEmail() async {
    await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (!mounted || ref.read(authControllerProvider).hasError) return;

    setState(() {
      notice = VerificationNotice.emailResent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authOperation = ref.watch(authControllerProvider);

    final isLoading = authOperation.isLoading;

    final authErrorCode = switch (authOperation.error) {
      AuthException(:final code) => code,
      _ => null,
    };

    return Column(
      children: [
        EmailVerificationFeedback(
          notice: notice,
          authErrorCode: authErrorCode,
          email: widget.email,
        ),
        SolidButtonWithLoading(
          label: "Check verification status",
          isLoading: isLoading,
          onPressed: checkEmailVerification,
        ),
        const SizedBox(height: AppSpacing.s8),
        SolidButtonWithLoading(
          label: 'Resend verification email',
          backgroundColor: AppColors.card,
          textColor: AppColors.onSurface,
          loadingLabel: 'Resend verification email',
          isLoading: isLoading,
          onPressed: resendVerificationEmail,
        ),
      ],
    );
  }
}
