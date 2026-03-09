import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final workoutsPerWeekProvider = 
  AsyncNotifierProvider<WorkoutsPerWeekNotifier, int>(
    WorkoutsPerWeekNotifier.new
  );

class WorkoutsPerWeekNotifier extends AsyncNotifier<int> {

  @override
  FutureOr<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsPerWeekSaved = prefs.getInt('workouts_per_week');

    return workoutsPerWeekSaved ?? 4;
  }

  Future<void> save(int newWorkoutsPerWeek) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('workouts_per_week', newWorkoutsPerWeek);
    state = AsyncData(newWorkoutsPerWeek);
  }
}