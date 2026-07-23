import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/fa_wrong_folder/exercises_in_a_day_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/providers/persisted/split_days.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/active_split_days_options.dart';
import 'package:lifting_tracker_app/providers/presentation/preset_split_vm.dart';
import 'package:lifting_tracker_app/providers/presentation/split_day_summary_tile.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_focus.dart';

final dayNameProvider = AsyncNotifierProvider.autoDispose
    .family<DayNameNotifier, String, String>(DayNameNotifier.new);

class DayNameNotifier extends AsyncNotifier<String> {
  DayNameNotifier(this.dayId);

  final String dayId;

  @override
  Future<String> build() async {
    final db = await AppDatabase.getDatabase();

    final data = await db.rawQuery(
      '''
      SELECT name
      FROM split_days
      WHERE id = ?
      ''',
      [dayId],
    );

    if (data.isEmpty) {
      throw StateError('Split plan with id $dayId was not found.');
    }

    return data.first['name'] as String;
  }

  Future<void> renameDay(String newName) async {
    final db = await AppDatabase.getDatabase();

    final splitId = await db.transaction((txn) async {
      await txn.rawUpdate(
        '''
        UPDATE split_days
        SET name = ?
        WHERE id =?
        ''',
        [newName, dayId],
      );

      final data = await txn.rawQuery(
        '''
        SELECT split_id
        FROM split_days
        WHERE id = ?
        ''',
        [dayId],
      );

      if (data.isEmpty) {
        throw StateError('Cannot find split id with day id $dayId.');
      }

      return data.first['split_id'] as int;
    });

    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(splitDaysProvider(splitId));
    ref.invalidate(exercisesInADayProvider(dayId));
    ref.invalidate(splitDaySummaryProvider(dayId));
    ref.invalidate(presetSplitVmProvider);

    ref.invalidate(workoutFocusProvider);
    ref.invalidate(activeSplitDaysOptionsProvider);

    final pickedDayId = ref.read(pickedNextSessionProvider).value;

    if (pickedDayId == dayId) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }

    state = AsyncData(newName);
  }
}
