import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/app/shell/main_shell.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/onboarding_shell.dart';
import 'package:lifting_tracker_app/core/theme/app_theme.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goToMenuAsync = ref.watch(setupCompletionProvider);

    return MaterialApp(
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.2,
          child: child!,
        );
      },
      home: goToMenuAsync.when(
        loading: () => Scaffold(body: CircularProgressIndicator()),
        error: (_, _) => Scaffold(
          body: Center(child: Text('An error has occured! Try again.')),
        ),
        data: (goToMenu) {
          if (goToMenu) {
            return const MainShell();
          } else {
            return const OnboardingShell();
          }
        },
      ),
    );
  }
}
