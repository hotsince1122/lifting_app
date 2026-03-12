import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/week_progress_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

final workoutsPerWeekProvider = 
  AsyncNotifierProvider<WorkoutsPerWeekNotifier, WeekProgressStatus>(
    WorkoutsPerWeekNotifier.new
  );

class WorkoutsPerWeekNotifier extends AsyncNotifier<WeekProgressStatus> {

  @override
  FutureOr<WeekProgressStatus> build() async {
    final prefs = await SharedPreferences.getInstance();
    final target = prefs.getInt('workouts_per_week_target');
    final progress = prefs.getInt('workouts_per_week_progress');

    return WeekProgressStatus(target ?? 1, progress ?? 1);
  }

  Future<void> saveNewTarget (int target) async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('workouts_per_week_target', target);
    state = AsyncData(WeekProgressStatus(target, current.progress));
  }

  Future<void> incrementProgress () async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('workouts_per_week_progress', current.progress + 1);
    state = AsyncData(WeekProgressStatus(current.target, current.progress + 1));
  }

  Future<void> resetProgress () async {
    final current = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('workouts_per_week_progress', 0);
    state = AsyncData(WeekProgressStatus(current.target, 0));
  }
}