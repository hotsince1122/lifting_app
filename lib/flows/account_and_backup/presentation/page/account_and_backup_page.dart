import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/simple_app_bar.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/account_actions_section.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/current_authentication_state.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/widgets/progress_protection_notice.dart';
import 'package:lifting_tracker_app/flows/account_and_backup/presentation/widgets/backup_section.dart';

class AccountAndBackupPage extends StatelessWidget {
  const AccountAndBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleAppBar('Account & Backup'),
      body: SafeArea(
        right: true,
        left: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const CurrentAuthenticationState(),
                  const SizedBox(height: AppSpacing.s24),
                  const ProgressProtectionNotice(),
                  const BackupSection(),
                  const SizedBox(height: AppSpacing.s16),
                  const AccountActionsSection(),
                  const SizedBox(height: AppSpacing.s16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
