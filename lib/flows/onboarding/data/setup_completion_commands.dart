import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setAsCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  final didSave = await prefs.setBool(setupStatusKey, true);

  if (!didSave) {
    throw StateError('Could not persist onboarding completion.');
  }
}

Future<void> reset() async {
  final prefs = await SharedPreferences.getInstance();
  final didSave = await prefs.setBool(setupStatusKey, false);

  if (!didSave) {
    throw StateError('Could not reset onboarding completion.');
  }
}
