import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_controller.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_credentials_validation.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_exception.dart';
import 'package:lifting_tracker_app/features/authentication/domain/auth_provider_type.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/authentication_flow_result.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/pages/verify_your_email_page.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/feedback/authentication_feedback.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/disabled_while_loading.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/solid_button_with_loading.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_auth_text_field.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/sign_in/email_authentication_method_selector.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/widgets/account_actions/reset_password_modal.dart';

class EmailAuthenticationPage extends ConsumerStatefulWidget {
  const EmailAuthenticationPage({super.key});

  @override
  ConsumerState<EmailAuthenticationPage> createState() =>
      _EmailAuthenticationPageState();
}

class _EmailAuthenticationPageState
    extends ConsumerState<EmailAuthenticationPage> {
  final formKey = GlobalKey<FormState>();

  EmailAuthenticationMethod authMethod =
      EmailAuthenticationMethod.createAccount;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatedPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideRepeatedPassword = true;
  bool hasAttemptedSubmit = false;

  void onTap(EmailAuthenticationMethod selectedMethod) {
    if (authMethod == selectedMethod) return;

    clearAuthOperationError();

    setState(() {
      authMethod = selectedMethod;
    });
  }

  void clearAuthOperationError([String? _]) {
    if (ref.read(authControllerProvider).hasError) {
      ref.invalidate(authControllerProvider);
    }
  }

  Future<void> checkIfEmailIsVerified() async {
    final authOperation = ref.read(authControllerProvider);

    if (authOperation.hasError || !mounted) return;

    final user = await ref.refresh(authStateProvider.future);

    if (!mounted || user == null) return;

    if (user.isEmailVerified) {
      Navigator.of(context).pop(AuthenticationFlowResult.authenticated);
      return;
    }

    await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (!mounted) return;

    final result = await Navigator.of(context).push<AuthenticationFlowResult>(
      MaterialPageRoute(
        builder: (_) => VerifyYourEmailPage(
          email: user.email ?? emailController.text.trim(),
        ),
      ),
    );

    if (!mounted || result == null) return;

    Navigator.of(context).pop(result);
  }

  Future<void> submit() async {
    setState(() {
      hasAttemptedSubmit = true;
    });

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    switch (authMethod) {
      case EmailAuthenticationMethod.createAccount:
        await ref
            .read(authControllerProvider.notifier)
            .createAccountWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
              passwordConfirmation: repeatedPasswordController.text,
            );
        break;
      case EmailAuthenticationMethod.signIn:
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
        break;
    }

    await checkIfEmailIsVerified();
  }

  String? validateEmailField(String? value) {
    return switch (validateEmail(value ?? '')) {
      AuthInputValidationError.emptyEmail => 'Email is required.',
      _ => null,
    };
  }

  String? validatePasswordField(String? value) {
    return switch (validatePassword(value ?? '')) {
      AuthInputValidationError.emptyPassword => 'Password is required.',
      _ => null,
    };
  }

  String? validatePasswordConfirmationField(String? value) {
    return switch (validatePasswordConfirmation(
      password: passwordController.text,
      confirmation: value ?? '',
    )) {
      AuthInputValidationError.emptyPasswordConfirmation =>
        'Please confirm your password.',
      AuthInputValidationError.passwordsDoNotMatch => 'Passwords do not match.',
      _ => null,
    };
  }

  String? emailFirebaseError(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.invalidEmail => 'Enter a valid email address.',
      AuthErrorCode.emailAlreadyInUse =>
        'An account already exists with this email.',
      _ => null,
    };
  }

  String? passwordFirebaseError(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.weakPassword =>
        'This password does not meet the security requirements.',
      _ => null,
    };
  }

  String get authMethodLabel => switch (authMethod) {
    EmailAuthenticationMethod.createAccount => 'Create account',
    EmailAuthenticationMethod.signIn => 'Sign in',
  };

  IconButton visibilityIcon(bool hide, VoidCallback onPressed) {
    return IconButton(
      key: ValueKey(hide),
      onPressed: onPressed,
      style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
      icon: Icon(
        !hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    repeatedPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);

    final authOperation = ref.watch(authControllerProvider);

    final isLoading = authOperation.isLoading;
    final authErrorCode = switch (authOperation.error) {
      AuthException(:final code) => code,
      _ => null,
    };

    final forgotPasswordAction = AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      child: authMethod == EmailAuthenticationMethod.signIn
          ? DisabledWhileLoading(
              isLoading: isLoading,
              child: GestureDetector(
                onTap: () async {
                  await ResetPasswordModal.openSheet(
                    context,
                    emailController.text.trim(),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );

    final emailFieldConfig = EmailAuthTextFieldConfig(
      title: 'Email',
      hintText: 'you@example.com',
      obscureText: false,
      suffixIconButton: null,
      labelAction: null,
      controller: emailController,
      validator: validateEmailField,
      externalErrorText: emailFirebaseError(authErrorCode),
      onChanged: clearAuthOperationError,
    );

    final passwordFieldConfig = EmailAuthTextFieldConfig(
      title: 'Password',
      hintText: 'Your password',
      obscureText: hidePassword,
      suffixIconButton: visibilityIcon(hidePassword, () {
        setState(() {
          hidePassword = !hidePassword;
        });
      }),
      labelAction: forgotPasswordAction,
      controller: passwordController,
      validator: validatePasswordField,
      externalErrorText: passwordFirebaseError(authErrorCode),
      onChanged: clearAuthOperationError,
    );

    final passwordConfirmationFieldConfig = EmailAuthTextFieldConfig(
      title: 'Confirm password',
      hintText: 'Repeat your password',
      obscureText: hideRepeatedPassword,
      suffixIconButton: visibilityIcon(hideRepeatedPassword, () {
        setState(() {
          hideRepeatedPassword = !hideRepeatedPassword;
        });
      }),
      labelAction: null,
      controller: repeatedPasswordController,
      validator: validatePasswordConfirmationField,
      onChanged: clearAuthOperationError,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: AnimatedSwitcher(
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [...previousChildren, ?currentChild],
            );
          },
          duration: Duration(milliseconds: 120),
          child: Text(
            key: ValueKey(authMethod),
            authMethodLabel,
            textAlign: TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(
            horizontal: AppSpacing.s16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Form(
              key: formKey,
              autovalidateMode: hasAttemptedSubmit
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.s8),
                  EmailAuthenticationMethodSelector(
                    method: authMethod,
                    onSelected: onTap,
                    isLoading: isLoading,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AuthenticationFeedback(
                            errorCode: authErrorCode,
                            provider: AuthProviderType.emailPassword,
                            flow: AuthFeedbackFlow.authentication,
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          EmailAuthTextField(
                            isLoading: isLoading,
                            config: emailFieldConfig,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          EmailAuthTextField(
                            isLoading: isLoading,
                            config: passwordFieldConfig,
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axisAlignment: -1,
                                  child: child,
                                ),
                              );
                            },
                            child:
                                authMethod ==
                                    EmailAuthenticationMethod.createAccount
                                ? Column(
                                    children: [
                                      const SizedBox(height: AppSpacing.s12),
                                      EmailAuthTextField(
                                        key: const ValueKey('confirmPassword'),
                                        isLoading: isLoading,
                                        config: passwordConfirmationFieldConfig,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('noConfirmPassword'),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.s20),
                          SolidButtonWithLoading(
                            label: authMethodLabel,
                            isLoading: isLoading,
                            onPressed: () => submit(),
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
      ),
    );
  }
}
