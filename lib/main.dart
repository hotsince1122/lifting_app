import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/firebase_options.dart';
import 'package:lifting_tracker_app/app/shell/main_shell.dart';
import 'package:lifting_tracker_app/core/theme/compressed_text_scaler.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/onboarding_shell.dart';
import 'package:lifting_tracker_app/core/theme/app_theme.dart';
import 'package:lifting_tracker_app/flows/onboarding/application/setup_completion_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: CompressedTextScaler(
              delegate: mediaQuery.textScaler,
              compression: 0.4,
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15,
            ),
          ),
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
