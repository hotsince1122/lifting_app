import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:lifting_tracker_app/features/progress/data/week_streak_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/progress/data/week_streak_queries.dart'
    as queries;

const _resetStreak = 0;

final weekStreakProvider = AsyncNotifierProvider<WeekStreakController, int>(
  WeekStreakController.new,
);

class WeekStreakController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() async {
    return await queries.loadWeekStreak() ?? _resetStreak;
  }

  FutureOr<void> incrementStreak() async {
    final current = await queries.loadWeekStreak() ?? _resetStreak;
    final incrementedStreak = current + 1;

    await commands.saveWeekStreak(incrementedStreak);

    state = AsyncData(incrementedStreak);

    return;
  }

  Future<void> resetStreak() async {
    await commands.saveWeekStreak(_resetStreak);

    state = AsyncData(_resetStreak);

    return;
  }
}
