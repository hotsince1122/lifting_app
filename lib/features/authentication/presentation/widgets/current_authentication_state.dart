import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CurrentAuthenticationState extends StatelessWidget {
  const CurrentAuthenticationState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          GradientCard(
            gradientVariant: AppGradients.softCard,
            child: Row(
              children: [
                _ProfileIcon(),
                const SizedBox(width: AppSpacing.s8),
                Expanded(child: _SignedInState()),
                _CurrentStatePill(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIcon extends ConsumerWidget {
  const _ProfileIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryTransparent,
      ),
      child: authStateAsync.when(
        loading: () =>
            Icon(PhosphorIcons.user(), size: 18, color: AppColors.primary),
        error: (_, _) => Icon(Icons.close, size: 18, color: Colors.red),
        data: (authState) {
          if (authState == null || authState.email == null) {
            return Icon(
              PhosphorIcons.user(),
              size: 18,
              color: AppColors.primary,
            );
          }

          return Center(
            child: Text(
              authState.email!.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          );
        },
      ),
    );
  }
}

class _SignedInState extends ConsumerWidget {
  const _SignedInState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          Center(child: Text("An error has occurred...\nCan't connect.")),
      data: (authState) {
        String title = 'Guest';
        String providers = '';
        final hasGoogle =
            authState?.hasProvider(AuthProviderType.google) ?? false;

        if (authState != null) {
          if (authState.email != null) {
            title = authState.email!;
          }
          if (authState.providers.length > 2) {
            providers = '${authState.providers.length} sign-in methods';
          } else if (authState.providers.contains(
                AuthProviderType.emailPassword,
              ) &&
              hasGoogle) {
            providers = 'Google + email sign-in';
          } else if (authState.providers.contains(
            AuthProviderType.emailPassword,
          )) {
            providers = 'Email and password';
          } else {
            providers = 'Google sign-in';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                hasGoogle
                    ? Padding(
                        padding: EdgeInsetsGeometry.only(right: AppSpacing.s4),
                        child: Image.asset(
                          'assets/google.png',
                          height: AppSpacing.s8,
                          width: AppSpacing.s8,
                        ),
                      )
                    : SizedBox.shrink(),
                Text(
                  authState == null ? 'No account on this device' : providers,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CurrentStatePill extends ConsumerWidget {
  const _CurrentStatePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) => SolidCard(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.s4,
          horizontal: AppSpacing.s8,
        ),
        color: Colors.red.withValues(alpha: 0.12),
        borderColor: Colors.red.withValues(alpha: 0.48),
        child: Text(
          'Failed',
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: Colors.red),
        ),
      ),
      data: (authState) {
        if (authState == null) {
          return SolidCard(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.s4,
              horizontal: AppSpacing.s8,
            ),
            color: Colors.orange.withValues(alpha: 0.12),
            borderColor: Colors.orange.withValues(alpha: 0.48),
            child: Text(
              'Local only',
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: Colors.orange),
            ),
          );
        }

        if (!authState.isEmailVerified) {
          return SolidCard(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.s4,
              horizontal: AppSpacing.s8,
            ),
            color: Colors.orange.withValues(alpha: 0.12),
            borderColor: Colors.orange.withValues(alpha: 0.48),
            child: Text(
              'Unverified',
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: Colors.orange),
            ),
          );
        }

        return SolidCard(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.s4,
            horizontal: AppSpacing.s8,
          ),
          color: AppColors.primary.withValues(alpha: 0.12),
          borderColor: AppColors.primary.withValues(alpha: 0.48),
          child: Text(
            'Verified',
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
          ),
        );
      },
    );
  }
}