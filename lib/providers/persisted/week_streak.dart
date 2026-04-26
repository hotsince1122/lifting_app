import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _weekStreakKey = 'week_streak';
const _resetedStreak = 0;

final weekStreakProvider = AsyncNotifierProvider<WeekStreakNotifier, int>(
  WeekStreakNotifier.new
);

class WeekStreakNotifier extends AsyncNotifier<int> {

  @override
  FutureOr<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_weekStreakKey);

    return streak ?? _resetedStreak;
  }

  FutureOr<void> incrementStreak () async {
    final current = state.requireValue;
    final incrementedStreak = current + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStreakKey, incrementedStreak);

    state = AsyncData(incrementedStreak);

    return;
  }

  Future<void> resetStreak () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStreakKey, _resetedStreak);

    state = AsyncData(_resetedStreak);

    return;
  }
}
