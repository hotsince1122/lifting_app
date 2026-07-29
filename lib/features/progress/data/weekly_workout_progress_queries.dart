import 'package:lifting_tracker_app/features/progress/data/progress_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<int?> loadWeeklyWorkoutTarget() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(weeklyWorkoutTargetPreferenceKey);
}

Future<List<bool>?> loadWeeklyGymAttendance() async {
  final prefs = await SharedPreferences.getInstance();
  final encodedAttendance = prefs.getString(weeklyGymAttendancePreferenceKey);

  if (encodedAttendance == null) return null;

  return encodedAttendance.split('').map((value) => value == '1').toList();
}

Future<String?> loadWeeklyGymAttendanceWeekStart() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(weeklyGymAttendanceWeekStartPreferenceKey);
}
