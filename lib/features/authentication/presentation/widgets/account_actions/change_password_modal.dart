import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_close_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/account_modal_header.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_auth_text_field.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/solid_button_with_loading.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChangePasswordModal extends ConsumerStatefulWidget {
  const ChangePasswordModal({super.key});

  static Future<void> openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (_) => const ChangePasswordModal(),
    );
  }

  @override
  ConsumerState<ChangePasswordModal> createState() =>
      _ChangePasswordModalState();
}

class _ChangePasswordModalState extends ConsumerState<ChangePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscurePasswordConfirmation = true;
  bool _isSuccess = false;
  bool _hasClearedInitialFeedback = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasClearedInitialFeedback) return;

    _hasClearedInitialFeedback = true;
    _clearAuthFeedback();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    return switch (validatePassword(value ?? '')) {
      AuthInputValidationError.emptyPassword => 'Current password is required.',
      _ => null,
    };
  }

  String? _validateNewPassword(String? value) {
    return switch (validatePassword(value ?? '')) {
      AuthInputValidationError.emptyPassword => 'New password is required.',
      _ => null,
    };
  }

  String? _validatePasswordConfirmation(String? value) {
    return switch (validatePasswordConfirmation(
      password: _newPasswordController.text,
      confirmation: value ?? '',
    )) {
      AuthInputValidationError.emptyPasswordConfirmation =>
        'Confirm your new password.',
      AuthInputValidationError.passwordsDoNotMatch => 'Passwords do not match.',
      _ => null,
    };
  }

  String? _currentPasswordFirebaseError(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.invalidCredentials => 'Current password is incorrect.',
      _ => null,
    };
  }

  String? _newPasswordFirebaseError(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.weakPassword => 'Choose a stronger password and try again.',
      _ => null,
    };
  }

  void _clearAuthFeedback([String? _]) {
    if (ref.read(authControllerProvider).hasError) {
      ref.invalidate(authControllerProvider);
    }

    if (_isSuccess) {
      setState(() {
        _isSuccess = false;
      });
    }
  }

  void _closeModal() {
    _clearAuthFeedback();
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    if (_isSuccess) {
      setState(() {
        _isSuccess = false;
      });
    }

    await ref
        .read(authControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );

    if (!mounted || ref.read(authControllerProvider).hasError) return;

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _passwordConfirmationController.clear();
    _formKey.currentState?.reset();

    setState(() {
      _isSuccess = true;
    });
  }

  IconButton _visibilityButton({
    required bool isObscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: PhosphorIcon(
        isObscured ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
        size: 18,
        color: AppColors.primary,
      ),
    );
  }

  EmailAuthTextField _passwordField({
    required String title,
    required String hintText,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback toggleVisibility,
    required FormFieldValidator<String> validator,
    required bool isLoading,
    String? externalErrorText,
  }) {
    return EmailAuthTextField(
      config: EmailAuthTextFieldConfig(
        title: title,
        hintText: hintText,
        obscureText: isObscured,
        suffixIconButton: _visibilityButton(
          isObscured: isObscured,
          onPressed: toggleVisibility,
        ),
        labelAction: null,
        controller: controller,
        validator: validator,
        externalErrorText: externalErrorText,
        onChanged: _clearAuthFeedback,
      ),
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authOperation = ref.watch(authControllerProvider);
    final isLoading = authOperation.isLoading;
    final authErrorCode = switch (authOperation.error) {
      AuthException(:final code) => code,
      _ => null,
    };

    return ModalScaffold(
      heightFactor: 0.72,
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountModalHeader(
                    icon: PhosphorIcons.password(),
                    title: 'Change your password',
                    body:
                        'Enter your current password, then choose a new password for your account.',
                  ),
                  AuthenticationFeedback(
                    errorCode: authErrorCode,
                    provider: AuthProviderType.emailPassword,
                    flow: AuthFeedbackFlow.changePassword,
                    isSuccess: _isSuccess,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _passwordField(
                            title: 'Current password',
                            hintText: 'Enter your current password',
                            controller: _currentPasswordController,
                            isObscured: _obscureCurrentPassword,
                            toggleVisibility: () {
                              setState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
                              });
                            },
                            validator: _validateCurrentPassword,
                            externalErrorText: _currentPasswordFirebaseError(
                              authErrorCode,
                            ),
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          _passwordField(
                            title: 'New password',
                            hintText: 'Enter your new password',
                            controller: _newPasswordController,
                            isObscured: _obscureNewPassword,
                            toggleVisibility: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            validator: _validateNewPassword,
                            externalErrorText: _newPasswordFirebaseError(
                              authErrorCode,
                            ),
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          _passwordField(
                            title: 'Confirm new password',
                            hintText: 'Repeat your new password',
                            controller: _passwordConfirmationController,
                            isObscured: _obscurePasswordConfirmation,
                            toggleVisibility: () {
                              setState(() {
                                _obscurePasswordConfirmation =
                                    !_obscurePasswordConfirmation;
                              });
                            },
                            validator: _validatePasswordConfirmation,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: AppSpacing.s20),
                          DisabledWhileLoading(
                            isLoading: isLoading,
                            child: SolidButtonWithLoading(
                              label: 'Change password',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: ModalCloseButton(
              onPressed: _closeModal,
              isEnabled: !isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
