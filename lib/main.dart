import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/did_user_finish_setup.dart';
import 'package:lifting_tracker_app/screens/main_shell.dart';
import 'package:lifting_tracker_app/screens/onboarding.dart';
import 'package:lifting_tracker_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goToMenuAsync = ref.watch(didUserFinishSetupProvider);
    

    return MaterialApp(
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: goToMenuAsync.when(
        loading: () => Scaffold(body: CircularProgressIndicator()),
        error: (_, _) => Scaffold(
          body: Center(child: Text('An error has occured! Try again.')),
        ),
        data: (goToMenu) {
          if (goToMenu) {
            return const MainShell();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}
