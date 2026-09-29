import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/core/ui/tile/setting_action_tile.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/change_password_modal.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/delete_account_modal.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/sign_out_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountActionsSection extends ConsumerWidget {
  const AccountActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auhtStateAsync = ref.watch(authStateProvider);

    final carterRightIcon = PhosphorIcon(
      PhosphorIcons.caretRight(),
      size: 16,
      color: AppColors.primary,
    );

    return auhtStateAsync.when(
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
                        SettingActionTile(
                          icon: PhosphorIcons.password(),
                          title: 'Change password',
                          subtitle: 'Update your account password',
                          onTap: () => ChangePasswordModal.openSheet(context),
                          leading: carterRightIcon,
                        ),
                        const SettingActionDivider(),
                      ],
                      SettingActionTile(
                        icon: PhosphorIcons.signOut(),
                        title: 'Sign out',
                        subtitle: 'Data stays on this device',
                        onTap: () => SignOutModal.openSheet(context),
                        leading: carterRightIcon,
                      ),
                      const SettingActionDivider(),
                      SettingActionTile(
                        icon: PhosphorIcons.trash(),
                        title: 'Delete account',
                        subtitle: 'Permanently deletes your cloud backup',
                        tone: SettingActionTone.destructive,
                        onTap: () => DeleteAccountModal.openSheet(context),
                        leading: carterRightIcon,
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
