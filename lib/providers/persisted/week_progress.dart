import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/weekly_workout_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

final weeklyWorkoutProgressProvider =
    AsyncNotifierProvider<WorkoutsPerWeekNotifier, WeeklyWorkoutProgress>(
      WorkoutsPerWeekNotifier.new,
    );

class WorkoutsPerWeekNotifier extends AsyncNotifier<WeeklyWorkoutProgress> {
  @override
  FutureOr<WeeklyWorkoutProgress> build() async {
    final prefs = await SharedPreferences.getInstance();
    final target = prefs.getInt('workouts_per_week_target');
    final attendanceEncoded =
        prefs.getString('weekly_gym_attendance') ?? '1101000';
    return WeeklyWorkoutProgress(
      target ?? 1,
      _decodeAttendance(attendanceEncoded),
    );
  }

  Future<void> saveNewTarget(int target) async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workouts_per_week_target', target);
    state = AsyncData(
      WeeklyWorkoutProgress(target, current.weeklyGymAttendance),
    );
  }

  Future<void> updateProgress(int day) async {
    final index = day - 1; //in DateTime, Monday = 1
    if (index < 0 || index > 6) return;

    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();

    final updatedAttendance = List<bool>.from(current.weeklyGymAttendance);
    updatedAttendance[index] = true;

    await prefs.setString(
      'weekly_gym_attendance',
      _encodeAttendance(updatedAttendance),
    );
    state = AsyncData(WeeklyWorkoutProgress(current.target, updatedAttendance));
  }

  Future<void> resetProgress() async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekly_gym_attendance', '0000000');
    state = AsyncData(
      WeeklyWorkoutProgress(
        current.target,
        List<bool>.generate(7, (_) => false),
      ),
    );
  }

  int returnCurrentProgress() {
    final current = state.requireValue.weeklyGymAttendance;
    int currentProgress = 0;
    for (int i = 0; i < current.length; i++) {
      if (current[i] == true) currentProgress++;
    }
    return currentProgress;
  }
}

String _encodeAttendance(List<bool> attendance) {
  return attendance.map((e) => e ? '1' : '0').join();
}

List<bool> _decodeAttendance(String encoded) {
  return encoded.split('').map((e) => e == '1').toList();
}
