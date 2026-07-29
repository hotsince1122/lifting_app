import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/progress/application/week_streak_controller.dart';
import 'package:lifting_tracker_app/features/progress/data/weekly_workout_progress_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/progress/data/weekly_workout_progress_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/progress/domain/weekly_workout_progress.dart';

const _defaultTarget = 4;

final weeklyWorkoutProgressProvider =
    AsyncNotifierProvider<
      WeeklyWorkoutProgressController,
      WeeklyWorkoutProgress
    >(WeeklyWorkoutProgressController.new);

class WeeklyWorkoutProgressController
    extends AsyncNotifier<WeeklyWorkoutProgress> {
  @override
  FutureOr<WeeklyWorkoutProgress> build() async {
    // to reset week progress
    // await commands.saveWeeklyGymAttendance(_emptyAttendance());

    await _ensureDefaultTarget();
    await _resetProgressIfWeekChanged();
    final target = await queries.loadWeeklyWorkoutTarget() ?? _defaultTarget;
    final attendance =
        await queries.loadWeeklyGymAttendance() ?? _emptyAttendance();

    return WeeklyWorkoutProgress(target, attendance);
  }

  Future<void> _ensureDefaultTarget() async {
    if (await queries.loadWeeklyWorkoutTarget() == null) {
      await commands.saveWeeklyWorkoutTarget(_defaultTarget);
    }
  }

  Future<void> _resetProgressIfWeekChanged() async {
    final currentWeekStart = weekStartKey(DateTime.now());
    final savedWeekStart = await queries.loadWeeklyGymAttendanceWeekStart();

    if (savedWeekStart == null) {
      await commands.saveWeeklyGymAttendanceWeekStart(currentWeekStart);
      return;
    }

    if (savedWeekStart == currentWeekStart) return;

    final target = await queries.loadWeeklyWorkoutTarget() ?? _defaultTarget;
    final attendance =
        await queries.loadWeeklyGymAttendance() ?? _emptyAttendance();
    final currentProgress = attendance.where((didAttend) => didAttend).length;

    if (target <= currentProgress) {
      await ref.read(weekStreakProvider.notifier).incrementStreak();
    } else {
      await ref.read(weekStreakProvider.notifier).resetStreak();
    }

    await commands.saveWeeklyGymAttendance(_emptyAttendance());
    await commands.saveWeeklyGymAttendanceWeekStart(currentWeekStart);
  }

  Future<void> syncCurrentWeek() async {
    final previousWeekStart = await queries.loadWeeklyGymAttendanceWeekStart();

    await _resetProgressIfWeekChanged();

    if (previousWeekStart == null ||
        previousWeekStart == await queries.loadWeeklyGymAttendanceWeekStart()) {
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

    await commands.saveWeeklyWorkoutTarget(target);

    state = AsyncData(
      WeeklyWorkoutProgress(target, current.weeklyGymAttendance),
    );
  }

  Future<void> updateProgress(int day) async {
    final index = day - 1; //in DateTime, Monday = 1
    if (index < 0 || index > 6) return;

    await syncCurrentWeek();

    final current = state.requireValue;

    final updatedAttendance = List<bool>.from(current.weeklyGymAttendance);
    updatedAttendance[index] = true;

    await commands.saveWeeklyGymAttendance(updatedAttendance);
    state = AsyncData(WeeklyWorkoutProgress(current.target, updatedAttendance));
  }

  Future<void> resetProgress() async {
    final current = state.requireValue;

    await commands.saveWeeklyGymAttendance(_emptyAttendance());
    await commands.saveWeeklyGymAttendanceWeekStart(
      weekStartKey(DateTime.now()),
    );

    state = AsyncData(
      WeeklyWorkoutProgress(current.target, _emptyAttendance()),
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

  Future<bool> rollbackProgressIfRequired(
    DateTime finishedTime, {
    required bool hasAnotherWorkoutOnSameDay,
  }) async {
    final weekStartToParse = await queries.loadWeeklyGymAttendanceWeekStart();
    if (weekStartToParse == null) return false;

    final weekStart = DateTime.tryParse(weekStartToParse);
    if (weekStart == null) return false;

    if (weekStart.isAfter(finishedTime) || hasAnotherWorkoutOnSameDay) {
      return true;
    }

    final currentProgress =
        await queries.loadWeeklyGymAttendance() ?? _emptyAttendance();
    currentProgress[finishedTime.weekday - 1] = false;
    final target = await queries.loadWeeklyWorkoutTarget() ?? _defaultTarget;

    state = AsyncData(WeeklyWorkoutProgress(target, currentProgress));

    await commands.saveWeeklyGymAttendance(currentProgress);
    return true;
  }
}

List<bool> _emptyAttendance() => List<bool>.generate(7, (_) => false);

String weekStartKey(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final startOfWeek = currentDate.subtract(
    Duration(days: currentDate.weekday - 1),
  );
  final month = startOfWeek.month.toString().padLeft(2, '0');
  final day = startOfWeek.day.toString().padLeft(2, '0');
  return '${startOfWeek.year}-$month-$day';
}
