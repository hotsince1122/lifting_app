import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';

class EmailAuthTextFieldConfig {
  const EmailAuthTextFieldConfig({
    required this.title,
    required this.hintText,
    required this.obscureText,
    required this.suffixIconButton,
    required this.labelAction,
    required this.controller,
    required this.validator,
    this.externalErrorText,
    this.onChanged,
  });

  final String title;
  final String hintText;
  final bool obscureText;
  final IconButton? suffixIconButton;
  final Widget? labelAction;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String? externalErrorText;
  final ValueChanged<String>? onChanged;
}

class EmailAuthTextField extends StatelessWidget {
  const EmailAuthTextField({
    required this.config,
    required this.isLoading,
    super.key,
  });

  final EmailAuthTextFieldConfig config;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: config.controller.text,
      validator: config.validator,
      builder: (field) {
        final errorColor = Theme.of(context).colorScheme.error;
        final errorText = field.errorText ?? config.externalErrorText;
        final hasError = errorText != null;

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    config.title,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
                  ),
                  ?config.labelAction,
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              DisabledWhileLoading(
                isLoading: isLoading,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppThemeGradients.of(AppGradients.card),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: config.controller,
                    obscureText: config.obscureText,
                    onChanged: (value) {
                      field.didChange(value);
                      config.onChanged?.call(value);
                    },
                    decoration: InputDecoration(
                      hint: Text(
                        config.hintText,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: hasError ? errorColor : AppColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: hasError ? errorColor : AppColors.primary,
                        ),
                      ),
                      suffixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: config.suffixIconButton,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: AppSpacing.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      errorText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: errorColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
