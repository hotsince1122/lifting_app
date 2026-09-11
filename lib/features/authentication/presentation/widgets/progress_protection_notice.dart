import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/application/progress_protection_notice_provider.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/authentication_flow_result.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/continue_with_email_button.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/google_sign_in_button.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/verify_email/verify_email_actions.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/pages/email_authentication_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProgressProtectionNotice extends ConsumerWidget {
  const ProgressProtectionNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressProtectionNoticeAsync = ref.watch(
      progressProtectionNoticeProvider,
    );

    return progressProtectionNoticeAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('An unexpected error has occured!')),
      data: (progressProtectionNotice) {
        if (progressProtectionNotice == null) return SizedBox.shrink();

        return Column(
          children: [
            switch (progressProtectionNotice) {
              ProgressProtectionNoticeContent.guest =>
                _SignInOrCreateAccountNotice(),
              ProgressProtectionNoticeContent.verificationRequired =>
                _VerifyEmailNotice(),
            },
            const SizedBox(height: AppSpacing.s24),
          ],
        );
      },
    );
  }
}

enum _BackupStateTone { standard, alert, error }

class _NoticeLayout extends StatelessWidget {
  const _NoticeLayout({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.body,
    this.tone = _BackupStateTone.standard,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? body;
  final _BackupStateTone tone;

  @override
  Widget build(BuildContext context) {
    late Color accentColor;

    switch (tone) {
      case _BackupStateTone.standard:
        accentColor = AppColors.primary;
        break;
      case _BackupStateTone.alert:
        accentColor = Colors.orange;
        break;
      case _BackupStateTone.error:
        accentColor = Colors.red;
        break;
    }

    return SolidCard(
      borderColor: accentColor.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: PhosphorIcon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body != null
                ? const SizedBox(height: AppSpacing.s16)
                : SizedBox.shrink(),
            ?body,
          ],
        ),
      ),
    );
  }
}

class _SignInOrCreateAccountNotice extends ConsumerWidget {
  const _SignInOrCreateAccountNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authOperation = ref.watch(authControllerProvider);

    final isLoading = authOperation.isLoading;

    final authErrorCode = switch (authOperation.error) {
      AuthException(:final code) => code,
      _ => null,
    };

    return _NoticeLayout(
      icon: PhosphorIcons.cloudSlash(),
      title: 'Your progress isn’t backed up',
      subtitle: 'Your training data is stored only on this device.',
      tone: _BackupStateTone.alert,
      body: Column(
        children: [
          AuthenticationFeedback(
            errorCode: authErrorCode,
            provider: AuthProviderType.google,
            flow: AuthFeedbackFlow.authentication,
          ),
          GoogleSignInButton(
            isLoading: isLoading,
            onTap: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .signInWithGoogle();

              if (ref.read(authControllerProvider).hasError) return;
            },
          ),
          const SizedBox(height: AppSpacing.s12),
          ContinueWithEmailButton(
            isLoading: isLoading,
            onTap: () async {
              ref.invalidate(authControllerProvider);

              await Navigator.of(context).push<AuthenticationFlowResult>(
                MaterialPageRoute(
                  builder: (context) => const EmailAuthenticationPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerifyEmailNotice extends ConsumerStatefulWidget {
  const _VerifyEmailNotice();

  @override
  ConsumerState<_VerifyEmailNotice> createState() => _VerifyEmailNoticeState();
}

class _VerifyEmailNoticeState extends ConsumerState<_VerifyEmailNotice> {
  final didSendVerification = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Center(child: Text('An error has occurred!')),
      data: (authState) {
        if (authState == null || authState.email == null) {
          return SizedBox.shrink();
        }

        return _NoticeLayout(
          icon: PhosphorIcons.envelope(),
          tone: _BackupStateTone.alert,
          title: 'Verify your email',
          subtitle:
              'Verify your email to enable cloud backup and account recovery.',
          body: VerifyEmailActions(email: authState.email!),
        );
      },
    );
  }
}
