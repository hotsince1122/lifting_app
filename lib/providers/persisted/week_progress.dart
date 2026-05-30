import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/weekly_workout_progress.dart';
import 'package:lifting_tracker_app/providers/persisted/week_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

const _targetKey = 'workouts_per_week_target';
const _attendanceKey = 'weekly_gym_attendance';
const _attendanceWeekStartKey = 'weekly_gym_attendance_week_start';
const _emptyAttendance = '0000000';
const _defaultTarget = 4;

final weeklyWorkoutProgressProvider =
    AsyncNotifierProvider<WorkoutsPerWeekNotifier, WeeklyWorkoutProgress>(
      WorkoutsPerWeekNotifier.new,
    );

class WorkoutsPerWeekNotifier extends AsyncNotifier<WeeklyWorkoutProgress> {
  @override
  FutureOr<WeeklyWorkoutProgress> build() async {

    final prefs = await SharedPreferences.getInstance();

    // to reset week progress
    // await prefs.setString('weekly_gym_attendance', '0000000');

    await _ensureDefaultTarget(prefs);
    await _resetProgressIfWeekChanged(prefs);
    final target = prefs.getInt(_targetKey) ?? _defaultTarget;
    final attendanceEncoded =
        prefs.getString(_attendanceKey) ?? _emptyAttendance;
    return WeeklyWorkoutProgress(target, _decodeAttendance(attendanceEncoded));
  }

  Future<void> _ensureDefaultTarget(SharedPreferences prefs) async {
    if (!prefs.containsKey(_targetKey)) {
      await prefs.setInt(_targetKey, _defaultTarget);
    }
  }

  Future<void> _resetProgressIfWeekChanged(SharedPreferences prefs) async {
    final currentWeekStart = weekStartKey(DateTime.now());
    final savedWeekStart = prefs.getString(_attendanceWeekStartKey);

    if (savedWeekStart == null) {
      await prefs.setString(_attendanceWeekStartKey, currentWeekStart);
      return;
    }

    if (savedWeekStart == currentWeekStart) return;

    final target = prefs.getInt(_targetKey) ?? _defaultTarget;
    final attendanceEncoded =
        prefs.getString(_attendanceKey) ?? _emptyAttendance;
    final attendance = _decodeAttendance(attendanceEncoded);
    final currentProgress = attendance.where((didAttend) => didAttend).length;

    if (target <= currentProgress) {
      await ref.read(weekStreakProvider.notifier).incrementStreak();
    } else {
      await ref.read(weekStreakProvider.notifier).resetStreak();
    }

    await prefs.setString(_attendanceKey, _emptyAttendance);
    await prefs.setString(_attendanceWeekStartKey, currentWeekStart);
  }

  Future<void> syncCurrentWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final previousWeekStart = prefs.getString(_attendanceWeekStartKey);

    await _resetProgressIfWeekChanged(prefs);

    if (previousWeekStart == null ||
        previousWeekStart == prefs.getString(_attendanceWeekStartKey)) {
      return;
    }

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
    await prefs.setString(
      _attendanceWeekStartKey,
      weekStartKey(DateTime.now()),
    );
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

  Future<bool> rollbackProgressIfRequired(DateTime finishedTime, Transaction txn) async {
    final prefs = await SharedPreferences.getInstance();

    final (isRollbackRequired, hadError) = await checkIfRollbackIsRequired(prefs, finishedTime, txn);

    if (hadError) return false;

    if(!isRollbackRequired) return true;

    final currentProgressEncoded =
        prefs.getString(_attendanceKey) ?? _emptyAttendance;
    final currentProgressDecoded = _decodeAttendance(currentProgressEncoded);
    currentProgressDecoded[finishedTime.weekday - 1] = false;
    final target = prefs.getInt(_targetKey) ?? _defaultTarget;

    state = AsyncData(
      WeeklyWorkoutProgress(target, currentProgressDecoded),
    );

    await prefs.setString(_attendanceKey, _encodeAttendance(currentProgressDecoded));
    return true;
  }
}

String _encodeAttendance(List<bool> attendance) {
  return attendance.map((e) => e ? '1' : '0').join();
}

List<bool> _decodeAttendance(String encoded) {
  return encoded.split('').map((e) => e == '1').toList();
}

String weekStartKey(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final startOfWeek = currentDate.subtract(
    Duration(days: currentDate.weekday - 1),
  );
  final month = startOfWeek.month.toString().padLeft(2, '0');
  final day = startOfWeek.day.toString().padLeft(2, '0');
  return '${startOfWeek.year}-$month-$day';
}

Future<(bool, bool)> checkIfRollbackIsRequired(SharedPreferences prefs, DateTime finishedTime, Transaction txn) async {
  final weekStartToParse = prefs.getString(_attendanceWeekStartKey);
  if (weekStartToParse == null) return (false, true);

  final weekStart = DateTime.tryParse(weekStartToParse);
  if (weekStart == null) return (false, true);

  if (weekStart.isAfter(finishedTime)) return (false, false);

  final (startSeconds, endSeconds) = secondsInterval(finishedTime);

  final anyWorkoutsData = await txn.rawQuery(
    '''
    SELECT id
    FROM workout_sessions
    WHERE finished_at >= ? AND finished_at < ?
    ''', [startSeconds, endSeconds]
  );

  if(anyWorkoutsData.isEmpty) return (true, false);

  return (false, false);
}

(int, int) secondsInterval(DateTime date) {
  final startOfDay = DateTime(date.year, date.month, date.day);

  final startOfNextDay = DateTime(date.year, date.month, date.day + 1);

  final startSeconds = startOfDay.millisecondsSinceEpoch ~/ 1000;
  final endSeconds = startOfNextDay.millisecondsSinceEpoch ~/ 1000;

  return (startSeconds, endSeconds);
}
