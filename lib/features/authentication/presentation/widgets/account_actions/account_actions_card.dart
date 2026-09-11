import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/change_password_modal.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/delete_account_modal.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/sign_out_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountActionsCard extends ConsumerWidget {
  const AccountActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auhtStateAync = ref.watch(authStateProvider);

    return auhtStateAync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Center(child: Text('An error has occurred!')),
      data: (authState) {
        if (authState == null) {
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s4),
            child: Text(
              'Without an account, uninstalling the app or losing this device means losing your training history.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s4),
                  child: Text(
                    'ACCOUNT',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                SolidCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (authState.hasProvider(
                        AuthProviderType.emailPassword,
                      )) ...[
                        _AccountAction(
                          icon: PhosphorIcons.password(),
                          title: 'Change password',
                          subtitle: 'Update your account password',
                          onTap: () => ChangePasswordModal.openSheet(context),
                        ),
                        const _AccountActionDivider(),
                      ],
                      _AccountAction(
                        icon: PhosphorIcons.signOut(),
                        title: 'Sign out',
                        subtitle: 'Data stays on this device',
                        onTap: () => SignOutModal.openSheet(context),
                      ),
                      const _AccountActionDivider(),
                      _AccountAction(
                        icon: PhosphorIcons.trash(),
                        title: 'Delete account',
                        subtitle: 'Permanently deletes your cloud backup',
                        tone: _AccountActionTone.destructive,
                        onTap: () => DeleteAccountModal.openSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

enum _AccountActionTone { standard, destructive }

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tone = _AccountActionTone.standard,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final _AccountActionTone tone;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == _AccountActionTone.destructive;
    final accentColor = isDestructive ? Colors.red : AppColors.primary;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
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
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              PhosphorIcon(
                PhosphorIcons.caretRight(),
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActionDivider extends StatelessWidget {
  const _AccountActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppColors.cardBorder,
      endIndent: 12,
      indent: 12,
    );
  }
}
