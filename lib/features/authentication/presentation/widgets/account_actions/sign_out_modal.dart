import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_close_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/account_modal_header.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SignOutModal extends ConsumerStatefulWidget {
  const SignOutModal({super.key});

  static Future<void> openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (_) => const SignOutModal(),
    );
  }

  @override
  ConsumerState<SignOutModal> createState() => _SignOutModalState();
}

class _SignOutModalState extends ConsumerState<SignOutModal> {
  bool hasClearedInitialFeedback = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (hasClearedInitialFeedback) return;

    hasClearedInitialFeedback = true;
    _clearAuthError();
  }

  void _clearAuthError() {
    if (!ref.read(authControllerProvider).hasError) return;

    ref.invalidate(authControllerProvider);
  }

  void _close() {
    _clearAuthError();

    Navigator.of(context).pop();
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();

    if (!mounted || ref.read(authControllerProvider).hasError) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authOperation = ref.watch(authControllerProvider);
    final isLoading = authOperation.isLoading;

    return ModalScaffold(
      heightFactor: 0.34,
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AccountModalHeader(
                  title: 'Sign out?',
                  body:
                      'Your workouts stay on this device and in your cloud backup. Sign in again anytime to resume syncing.',
                ),
                if (authOperation.hasError) ...[
                  const SizedBox(height: AppSpacing.s12),
                  SolidCard(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    color: Colors.red.withValues(alpha: 0.12),
                    borderColor: Colors.red.withValues(alpha: 0.48),
                    child: Text(
                      'Couldn’t sign out. Check your connection and try again.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: Colors.red),
                    ),
                  ),
                ],
                const Spacer(),
                DisabledWhileLoading(
                  isLoading: isLoading,
                  child: SolidButton(
                    color: AppColors.card,
                    borderColor: Colors.red.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    onPressed: _signOut,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          PhosphorIcon(
                            PhosphorIcons.signOut(),
                            size: 18,
                            color: Colors.red,
                          ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          isLoading ? 'Signing out...' : 'Sign out',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: ModalCloseButton(onPressed: _close, isEnabled: !isLoading),
          ),
        ],
      ),
    );
  }
}
