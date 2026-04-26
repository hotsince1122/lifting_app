import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/weekly_workout_progress.dart';
import 'package:lifting_tracker_app/providers/persisted/week_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _targetKey = 'workouts_per_week_target';
const _attendanceKey = 'weekly_gym_attendance';
const _attendanceWeekKey = 'weekly_gym_attendance_week_start';
const _emptyAttendance = '0000000';

final weeklyWorkoutProgressProvider =
    AsyncNotifierProvider<WorkoutsPerWeekNotifier, WeeklyWorkoutProgress>(
      WorkoutsPerWeekNotifier.new,
    );

class WorkoutsPerWeekNotifier extends AsyncNotifier<WeeklyWorkoutProgress> {
  @override
  FutureOr<WeeklyWorkoutProgress> build() async {
    final prefs = await SharedPreferences.getInstance();

    //to reset week progress
    // await prefs.setString('weekly_gym_attendance', '0000000');

    await _resetProgressIfWeekChanged(prefs);
    final target = prefs.getInt(_targetKey);
    final attendanceEncoded =
        prefs.getString(_attendanceKey) ?? _emptyAttendance;
    return WeeklyWorkoutProgress(
      target ?? 4,
      _decodeAttendance(attendanceEncoded),
    );
  }

  Future<void> _resetProgressIfWeekChanged(SharedPreferences prefs) async {
    final currentWeekStart = _weekStartKey(DateTime.now());
    final savedWeekStart = prefs.getString(_attendanceWeekKey);
    
    final target = prefs.getInt(_targetKey);
    final attendanceEncoded = prefs.getString(_attendanceKey) ?? _emptyAttendance;
    final attendance = _decodeAttendance(attendanceEncoded);
    final currentProgress = attendance.where((didAttend) => didAttend).length;

    if (savedWeekStart == currentWeekStart || target == null) return;

    if (savedWeekStart != null) {
      if (target <= currentProgress) {
        await ref.read(weekStreakProvider.notifier).incrementStreak();
      } else {
        await ref.read(weekStreakProvider.notifier).resetStreak();
      }
    }

    await prefs.setString(_attendanceKey, _emptyAttendance);
    await prefs.setString(_attendanceWeekKey, currentWeekStart);
  }

  Future<void> syncCurrentWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final previousWeekStart = prefs.getString(_attendanceWeekKey);

    await _resetProgressIfWeekChanged(prefs);

    if (previousWeekStart == prefs.getString(_attendanceWeekKey)) return;

    final current = state.requireValue;
    state = AsyncData(
      WeeklyWorkoutProgress(
        current.target,
        List<bool>.generate(7, (_) => false),
      ),
    );
  }

  Future<void> saveNewTarget(int target) async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, target);
    state = AsyncData(
      WeeklyWorkoutProgress(target, current.weeklyGymAttendance),
    );
  }

  Future<void> updateProgress(int day) async {
    final index = day - 1; //in DateTime, Monday = 1
    if (index < 0 || index > 6) return;

    await syncCurrentWeek();

    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();

    final updatedAttendance = List<bool>.from(current.weeklyGymAttendance);
    updatedAttendance[index] = true;

    await prefs.setString(_attendanceKey, _encodeAttendance(updatedAttendance));
    state = AsyncData(WeeklyWorkoutProgress(current.target, updatedAttendance));
  }

  Future<void> resetProgress() async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attendanceKey, _emptyAttendance);
    await prefs.setString(_attendanceWeekKey, _weekStartKey(DateTime.now()));
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

String _weekStartKey(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final startOfWeek = currentDate.subtract(
    Duration(days: currentDate.weekday - 1),
  );
  final month = startOfWeek.month.toString().padLeft(2, '0');
  final day = startOfWeek.day.toString().padLeft(2, '0');
  return '${startOfWeek.year}-$month-$day';
}
