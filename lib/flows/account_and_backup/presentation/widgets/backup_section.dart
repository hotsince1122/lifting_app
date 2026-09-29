import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/core/ui/tile/setting_action_tile.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_controller.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/cloud_backup_providers.dart';
import 'package:lifting_tracker_app/features/cloud_backup/application/is_automatic_backup_enabled_controller.dart';
import 'package:lifting_tracker_app/features/history/application/completed_workouts_count_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Center(child: Text('An error has occurred!')),
      data: (authState) {
        if (authState == null || !authState.isEmailVerified) {
          return SizedBox.shrink();
        }

        final backupStateAsync = ref.watch(cloudBackupControllerProvider);
        final cachedDateAsync = ref.watch(lastBackupDateProvider(authState.id));
        final cachedDate = cachedDateAsync.value;

        String lastBackupSubtitle(DateTime uploadedAt, {bool cached = false}) {
          final formattedDate = DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(uploadedAt.toLocal());
          return cached
              ? 'Last known backup: $formattedDate'
              : 'Last successful backup: $formattedDate';
        }

        final backupSubtitle = backupStateAsync.when(
          loading: () => cachedDate == null
              ? 'Working on cloud backup…'
              : 'Checking cloud… · ${lastBackupSubtitle(cachedDate, cached: true)}',
          error: (_, _) => cachedDate == null
              ? 'Cloud backup needs attention'
              : lastBackupSubtitle(cachedDate, cached: true),
          data: (metadata) {
            if (metadata == null) {
              return 'No cloud backup yet';
            }
            return lastBackupSubtitle(metadata.uploadedAt);
          },
        );

        final completedWorkoutCountAsync = ref.watch(
          completedWorkoutCountProvider,
        );

        final completedWorkoutsCountLable = completedWorkoutCountAsync.when(
          loading: () => '...',
          error: (_, _) => 'x',
          data: (count) {
            return '$count workout${count != 1 ? 's' : ''}';
          },
        );

        final setting = ref.watch(isAutomaticBackupEnabledController);

        final isEnabled = setting.value ?? false;
        final isBusy = setting.isLoading;
        final canChange = !isBusy && setting.hasValue;

        ref.listen(isAutomaticBackupEnabledController, (previous, next) {
          if (next.hasError && previous?.error != next.error) {
            SnackBarError.show(
              context,
              'Could not save the automatic backup setting. Please try again.',
            );
          }
        });

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s4),
                child: Text(
                  'BACKUP',
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
                    SettingActionTile(
                      icon: PhosphorIcons.cloudArrowUp(),
                      title: 'Back up now',
                      subtitle: backupSubtitle,
                      onTap: () async {
                        if (backupStateAsync.isLoading) return;

                        await ref
                            .read(cloudBackupControllerProvider.notifier)
                            .backupNow();
                      },
                      leading: Text(
                        completedWorkoutsCountLable,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                    const SettingActionDivider(),
                    SettingActionTile(
                      icon: PhosphorIcons.downloadSimple(),
                      title: 'Restore from cloud backup',
                      subtitle:
                          "Replace this device's data with your latest backup",
                      onTap: () {},
                      leading: PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SettingActionDivider(),
                    SettingActionTile(
                      icon: PhosphorIcons.arrowsClockwise(),
                      title: 'Automatic backup',
                      subtitle: "Back up after every finished workout",
                      onTap: () {
                        if (!canChange) return;

                        ref
                            .read(isAutomaticBackupEnabledController.notifier)
                            .switchValue(!isEnabled);
                      },
                      leading: Transform.scale(
                        scale: 0.75,
                        child: CupertinoSwitch(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.cardSoftEnd,
                          thumbColor: AppColors.card,
                          value: isEnabled,
                          onChanged: canChange
                              ? (newValue) {
                                  ref
                                      .read(
                                        isAutomaticBackupEnabledController
                                            .notifier,
                                      )
                                      .switchValue(newValue);
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
