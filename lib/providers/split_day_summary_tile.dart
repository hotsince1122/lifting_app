import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/view_model/split_day_summary.dart';

Future<SplitDaySummary> _loadSummary(String dayId) async {
  final db = await AppDatabases.getDatabase();

  final rows = await db.rawQuery(
    '''
    SELECT e.muscle_group
    FROM day_exercises de
    JOIN exercises e ON e.id = de.exercise_id
    WHERE de.day_id = ?
    ORDER BY de.order_idx ASC
    ''',
    [dayId],
  );

  Set<String> muscleGroups = {};

  for (var row in rows) {
    String label = row['muscle_group'] as String;
    label = label[0].toUpperCase() + label.substring(1);
    muscleGroups.add(label);
  }

  return SplitDaySummary(exerciseCount: rows.length, muscleGroups: muscleGroups);
}

final splitDaySummaryProvider = 
    AsyncNotifierProvider.family<
      SplitDaySummaryNotifier,
      SplitDaySummary,
      String
    >(SplitDaySummaryNotifier.new);

class SplitDaySummaryNotifier extends AsyncNotifier<SplitDaySummary> {
  SplitDaySummaryNotifier(this.dayId);

  final String dayId;

  @override
  FutureOr<SplitDaySummary> build() {
    return _loadSummary(dayId);
  }

  Future<void> refresh() async {
    state = AsyncData(await _loadSummary(dayId));
  }
}