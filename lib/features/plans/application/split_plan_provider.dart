import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_plan.dart';

final splitPlanProvider = FutureProvider.autoDispose.family<SplitPlan?, int>((
  ref,
  splitId,
) async {
  final db = await AppDatabase.getDatabase();
  final data = await db.query(
    'split_plans',
    where: 'id = ?',
    whereArgs: [splitId],
    limit: 1,
  );

  if (data.isEmpty) return null;

  final row = data.first;
  final splitDays = await ref.watch(splitDaysProvider(splitId).future);
  var exerciseCount = 0;

  for (final splitDay in splitDays) {
    final exercises = await ref.watch(
      plannedExercisesProvider(splitDay.id).future,
    );
    exerciseCount += exercises.length;
  }

  return SplitPlan(
    id: splitId,
    name: row['name'] as String,
    isActive: row['is_active'] as int == 1,
    isPreset: row['is_preset'] as int == 1,
    cycleLengthInDays: splitDays.length,
    exerciseCount: exerciseCount,
  );
});
