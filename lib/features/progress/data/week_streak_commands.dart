import 'package:lifting_tracker_app/features/progress/data/progress_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveWeekStreak(int streak) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(weekStreakPreferenceKey, streak);
}
