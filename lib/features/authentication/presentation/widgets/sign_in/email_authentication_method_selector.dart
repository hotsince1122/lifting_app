import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';

enum EmailAuthenticationMethod { createAccount, signIn }

class EmailAuthenticationMethodSelector extends StatelessWidget {
  const EmailAuthenticationMethodSelector({
    required this.method,
    required this.onSelected,
    required this.isLoading,
    super.key,
  });

  final EmailAuthenticationMethod method;
  final ValueChanged<EmailAuthenticationMethod> onSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Widget methodButton({
      required bool isSelected,
      required String label,
      required EmailAuthenticationMethod methodToSelect,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelected(methodToSelect),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? AppColors.cardBorder : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DisabledWhileLoading(
      isLoading: isLoading,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            methodButton(
              isSelected: method == EmailAuthenticationMethod.createAccount,
              label: 'Create account',
              methodToSelect: EmailAuthenticationMethod.createAccount,
            ),
            methodButton(
              isSelected: method == EmailAuthenticationMethod.signIn,
              label: 'Sign in',
              methodToSelect: EmailAuthenticationMethod.signIn,
            ),
          ],
        ),
      ),
    );
  }
}
