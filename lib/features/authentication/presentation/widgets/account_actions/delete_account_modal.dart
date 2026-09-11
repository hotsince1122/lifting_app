import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_close_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/account_modal_header.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/sign_out_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DeleteAccountModal extends StatelessWidget {
  const DeleteAccountModal({this.onDeletePermanently, super.key});

  final VoidCallback? onDeletePermanently;

  static Future<void> openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (_) => const DeleteAccountModal(),
    );
  }

  Future<void> _openSignOutInstead(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    await SignOutModal.openSheet(navigator.context);
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      heightFactor: 0.42,
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccountModalHeader(
                  icon: PhosphorIcons.trash(),
                  accentColor: Colors.red,
                  title: 'Delete your account?',
                  body:
                      'This permanently deletes your cloud backup and account. Your local history stays on this device. This can’t be undone.',
                ),
                const Spacer(),
                IgnorePointer(
                  child: SolidButton(
                    color: Colors.red,
                    borderColor: Colors.red,
                    //not implemented yet
                    isActive: true,
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    onPressed: onDeletePermanently ?? () {},
                    child: Text(
                      'Delete permanently',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                TextButton(
                  onPressed: () => _openSignOutInstead(context),
                  child: Text(
                    'Sign out instead',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(top: 0, right: 0, child: ModalCloseButton()),
        ],
      ),
    );
  }
}
