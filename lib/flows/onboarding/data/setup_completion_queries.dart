import 'package:lifting_tracker_app/flows/onboarding/data/setup_completion_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> loadSetupCompletion() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(setupStatusKey) ?? false;
}
