import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _weekStreakKey = 'week_streak';
const _resetStreak = 0;

final weekStreakProvider = AsyncNotifierProvider<WeekStreakController, int>(
  WeekStreakController.new,
);

class WeekStreakController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_weekStreakKey);

    return streak ?? _resetStreak;
  }

  FutureOr<void> incrementStreak() async {
    final current = await _loadStoredStreak();
    final incrementedStreak = current + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStreakKey, incrementedStreak);

    state = AsyncData(incrementedStreak);

    return;
  }

  Future<int> _loadStoredStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_weekStreakKey) ?? _resetStreak;
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStreakKey, _resetStreak);

    state = AsyncData(_resetStreak);

    return;
  }
}
