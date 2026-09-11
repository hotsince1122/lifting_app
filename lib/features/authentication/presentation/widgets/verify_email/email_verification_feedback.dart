import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/verify_email/verification_notice.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmailVerificationFeedback extends StatelessWidget {
  const EmailVerificationFeedback({
    required this.notice,
    required this.authErrorCode,
    required this.email,
    super.key,
  });

  final VerificationNotice notice;
  final AuthErrorCode? authErrorCode;
  final String email;

  @override
  Widget build(BuildContext context) {
    if (authErrorCode != null) {
      return AuthenticationFeedback(
        errorCode: authErrorCode,
        provider: AuthProviderType.emailPassword,
        flow: AuthFeedbackFlow.emailVerification,
      );
    }

    return switch (notice) {
      VerificationNotice.none => const SizedBox.shrink(),
      VerificationNotice.emailResent => _CompactNotice(
        icon: Icons.check,
        text: 'Verification email sent again to $email.',
        color: AppColors.primary,
      ),
      VerificationNotice.notVerified => _CompactNotice(
        icon: PhosphorIcons.warning(),
        text: 'Email isn’t verified yet. Open the link, then try again.',
        color: Colors.orange,
      ),
    };
  }
}

class _CompactNotice extends StatelessWidget {
  const _CompactNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
