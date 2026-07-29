import 'package:lifting_tracker_app/features/progress/data/progress_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<int?> loadWeekStreak() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(weekStreakPreferenceKey);
}
