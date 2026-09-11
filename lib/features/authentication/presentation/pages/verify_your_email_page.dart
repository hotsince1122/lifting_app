import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/authentication_flow_result.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/verify_email/verify_email_actions.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class VerifyYourEmailPage extends ConsumerStatefulWidget {
  const VerifyYourEmailPage({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyYourEmailPage> createState() =>
      _VerifyYourEmailPageState();
}

class _VerifyYourEmailPageState extends ConsumerState<VerifyYourEmailPage> {
  @override
  Widget build(BuildContext context) {
    void finishAuthentication() {
      Navigator.of(context).pop(AuthenticationFlowResult.authenticated);
    }

    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        right: true,
        left: true,
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(
            vertical: AppSpacing.s32,
            horizontal: AppSpacing.s16,
          ),
          child: authStateAsync.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('An error has occurred!')),
            data: (authState) {
              if (authState == null) {
                return const Center(child: Text('An error has occurred!'));
              }

              return SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Header(widget.email, authState.isEmailVerified),
                      authState.isEmailVerified
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.s20,
                              ),
                              child: SolidButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.s16,
                                ),
                                onPressed: finishAuthentication,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppColors.card,
                                    ),
                                    const SizedBox(width: AppSpacing.s4),
                                    Text(
                                      'Continue',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(color: AppColors.card),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                VerifyEmailActions(email: widget.email),
                                const SizedBox(height: AppSpacing.s20),
                                _UnverifiedSection(
                                  onContinue: finishAuthentication,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.email, this.isVerified);

  final String email;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradientVariant: AppGradients.card,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTransparent,
              ),
              child: Center(
                child: Icon(
                  isVerified ? Icons.check : PhosphorIcons.mailbox(),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              isVerified ? 'Email verified' : 'Verify your email',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.s12),
            isVerified
                ? Text(
                    'Your account is fully set up and ready to back up your training data.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
                  )
                : Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primary,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a verification link to '),
                        TextSpan(
                          text: email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const TextSpan(
                          text: '. Open the link, then return here.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }
}

class _UnverifiedSection extends StatelessWidget {
  const _UnverifiedSection({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onContinue,
          child: Text(
            'Continue for now',
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'You can verify later from Account & Backup, but until then, your progress won’t be protected by cloud backup.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
