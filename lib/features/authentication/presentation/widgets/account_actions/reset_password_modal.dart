import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/buttons/solid_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_close_button.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_auth_text_field.dart';

class ResetPasswordModal extends ConsumerStatefulWidget {
  const ResetPasswordModal({required this.email, super.key});

  final String email;

  static Future<void> openSheet(BuildContext context, String email) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => ResetPasswordModal(email: email),
    );
  }

  @override
  ConsumerState<ResetPasswordModal> createState() => _ResetPasswordModalState();
}

class _ResetPasswordModalState extends ConsumerState<ResetPasswordModal> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();
  bool isSuccess = false;
  bool hasClearedInitialFeedback = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.email);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (hasClearedInitialFeedback) return;

    hasClearedInitialFeedback = true;
    clearAuthFeedback();
  }

  String? validateEmailField(String? value) {
    return switch (validateEmail(value ?? '')) {
      AuthInputValidationError.emptyEmail => 'Email is required.',
      _ => null,
    };
  }

  String? emailFirebaseError(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.invalidEmail => 'Enter a valid email address.',
      _ => null,
    };
  }

  void clearAuthFeedback([String? _]) {
    if (ref.read(authControllerProvider).hasError) {
      ref.invalidate(authControllerProvider);
    }

    if (isSuccess) {
      setState(() {
        isSuccess = false;
      });
    }
  }

  void closeModal() {
    clearAuthFeedback();
    Navigator.of(context).pop();
  }

  void submit(String email) async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    if (isSuccess) {
      setState(() {
        isSuccess = false;
      });
    }

    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: email);

    if (!mounted || ref.read(authControllerProvider).hasError) return;

    setState(() {
      isSuccess = true;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      heightFactor: 0.5,
      Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: ModalCloseButton(
              onPressed: closeModal,
              isEnabled: !isLoading,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: SizedBox(
              width: double.infinity,
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.s20),
                    Text(
                      'Reset your password',
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              'Enter your email and we’ll send you a password reset link.',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(color: AppColors.primary),
                            ),
                            AuthenticationFeedback(
                              errorCode: authErrorCode,
                              provider: AuthProviderType.emailPassword,
                              flow: AuthFeedbackFlow.passwordReset,
                              isSuccess: isSuccess,
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            EmailAuthTextField(
                              config: EmailAuthTextFieldConfig(
                                title: 'Email',
                                hintText: 'you@example.com',
                                obscureText: false,
                                suffixIconButton: null,
                                labelAction: null,
                                controller: controller,
                                validator: validateEmailField,
                                externalErrorText: emailFirebaseError(
                                  authErrorCode,
                                ),
                                onChanged: clearAuthFeedback,
                              ),
                              isLoading: isLoading,
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            DisabledWhileLoading(
                              isLoading: isLoading,
                              child: SolidButton(
                                onPressed: () => submit(controller.text),
                                padding: const EdgeInsets.all(AppSpacing.s16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    isLoading
                                        ? Padding(
                                            padding: EdgeInsetsGeometry.only(
                                              right: AppSpacing.s8,
                                            ),
                                            child: SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                color: AppColors.card,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : SizedBox.shrink(),
                                    Text(
                                      isLoading
                                          ? 'Please wait...'
                                          : 'Send reset link',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(color: AppColors.card),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}
