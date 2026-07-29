import 'package:lifting_tracker_app/features/progress/data/progress_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveWeeklyWorkoutTarget(int target) async {
  final prefs = await SharedPreferences.getInstance();
  final didSave = await prefs.setInt(weeklyWorkoutTargetPreferenceKey, target);

  if (!didSave) {
    throw StateError('Could not save the weekly workout target.');
  }
}

Future<void> saveWeeklyGymAttendance(List<bool> attendance) async {
  final prefs = await SharedPreferences.getInstance();
  final encodedAttendance = attendance
      .map((didAttend) => didAttend ? '1' : '0')
      .join();

  await prefs.setString(weeklyGymAttendancePreferenceKey, encodedAttendance);
}

Future<void> saveWeeklyGymAttendanceWeekStart(String weekStart) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(weeklyGymAttendanceWeekStartPreferenceKey, weekStart);
}
