import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/authentication_flow_result.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/continue_with_email_button.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/google_sign_in_button.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/pages/email_authentication_page.dart';

class ProtectYourProgressPage extends ConsumerWidget {
  const ProtectYourProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authOperation = ref.watch(authControllerProvider);

    final isLoading = authOperation.isLoading;

    final authErrorCode = switch (authOperation.error) {
      AuthException(:final code) => code,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.s24),
            GoogleSignInButton(
              isLoading: isLoading,
              onTap: () async {
                await ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle();

                if (ref.read(authControllerProvider).hasError) return;
                await ref.read(setupCompletionProvider.notifier).complete();
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            ContinueWithEmailButton(
              isLoading: isLoading,
              onTap: () async {
                ref.invalidate(authControllerProvider);

                final result = await Navigator.of(context)
                    .push<AuthenticationFlowResult>(
                      MaterialPageRoute(
                        builder: (context) => const EmailAuthenticationPage(),
                      ),
                    );

                if (!context.mounted ||
                    result != AuthenticationFlowResult.authenticated) {
                  return;
                }

                await ref.read(setupCompletionProvider.notifier).complete();
              },
            ),
            AuthenticationFeedback(
              errorCode: authErrorCode,
              provider: AuthProviderType.google,
              flow: AuthFeedbackFlow.authentication,
            ),
            const SizedBox(height: AppSpacing.s12),
            _GuestSection(
              isDisabled: isLoading,
              endSetup: () async {
                try {
                  await ref.read(setupCompletionProvider.notifier).complete();
                } catch (_) {
                  if (!context.mounted) return;
                  SnackBarError.show(
                    context,
                    'Could not complete setup. Try again!',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradientVariant: AppGradients.softCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryTransparent,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Protect your progress',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Create an account to back up your training data and restore it on another device. You can continue without an account.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GuestSection extends StatelessWidget {
  const _GuestSection({required this.isDisabled, required this.endSetup});

  final bool isDisabled;
  final VoidCallback endSetup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              Expanded(
                child: const Divider(color: AppColors.cardBorder, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Text(
                  'or',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
              Expanded(
                child: const Divider(color: AppColors.cardBorder, thickness: 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        TextButton(
          onPressed: isDisabled ? () {} : endSetup,
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: Opacity(
            opacity: isDisabled ? 0.18 : 1,
            child: Text(
              'Continue without an account',
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Your progress will remain on this device and won’t be protected in the cloud.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
