import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_id.dart';
import 'package:lifting_tracker_app/fa_wrong_folder/exercises_in_a_day_controller.dart';
import 'package:lifting_tracker_app/features/workouts/application/picked_next_session_controller.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';
import 'package:lifting_tracker_app/providers/presentation/preset_split_vm.dart';
import 'package:lifting_tracker_app/providers/presentation/split_day_summary_tile.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_focus.dart';

Future<List<SplitDay>> _loadSplitDays(int splitId) async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
    SELECT name, order_idx AS orderIndex, id
    FROM split_days
    WHERE split_id = ?
    ORDER BY order_idx
    ''',
    [splitId],
  );

  return data
      .map(
        (row) => SplitDay(
          name: row['name'] as String,
          orderIndex: row['orderIndex'] as int,
          id: row['id'] as String,
        ),
      )
      .toList();
}

final splitDaysProvider = AsyncNotifierProvider.autoDispose
    .family<SplitDaysNotifier, List<SplitDay>, int>(SplitDaysNotifier.new);

class SplitDaysNotifier extends AsyncNotifier<List<SplitDay>> {
  SplitDaysNotifier(this.splitId);

  final int splitId;

  @override
  FutureOr<List<SplitDay>> build() {
    return _loadSplitDays(splitId);
  }

  Future<void> deleteSplitDay(String splitDayId) async {
    final db = await AppDatabase.getDatabase();

    await db.transaction<void>((txn) async {
      final splitDays = await txn.rawQuery(
        '''
        SELECT *
        FROM split_days
        WHERE id = ? AND split_id = ?
        LIMIT 1
        ''',
        [splitDayId, splitId],
      );

      if (splitDays.isEmpty) return;

      await txn.rawDelete(
        '''
        DELETE FROM day_exercises
        WHERE day_id = ?
        ''',
        [splitDayId],
      );

      await txn.rawUpdate(
        '''
        UPDATE workout_sessions
        SET day_id = NULL
        WHERE day_id = ?
        ''',
        [splitDayId],
      );

      final deletedDays = await txn.rawDelete(
        '''
        DELETE FROM split_days
        WHERE id = ? AND split_id = ?
        ''',
        [splitDayId, splitId],
      );

      if (deletedDays != 1) {
        throw Exception('Expected to delete exactly one split day.');
      }

      final remainingDays = await txn.rawQuery(
        '''
        SELECT id, order_idx
        FROM split_days
        WHERE split_id = ?
        ORDER BY order_idx, id
        ''',
        [splitId],
      );

      for (int i = 0; i < remainingDays.length; i++) {
        final currentOrderIndex = remainingDays[i]['order_idx'] as int;

        if (currentOrderIndex == i) continue;

        final updatedDays = await txn.rawUpdate(
          '''
          UPDATE split_days
          SET order_idx = ?
          WHERE id = ? AND split_id = ?
          ''',
          [i, remainingDays[i]['id'] as String, splitId],
        );

        if (updatedDays != 1) {
          throw Exception('Could not compact split day indexes.');
        }
      }
    });

    state = AsyncData(await _loadSplitDays(splitId));

    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(exercisesInADayProvider(splitDayId));
    ref.invalidate(splitDaySummaryProvider(splitDayId));
    ref.invalidate(presetSplitVmProvider);

    final activeSplitId = await ref.read(activeSplitIdProvider.future);

    if (activeSplitId == splitId) {
      ref.invalidate(workoutFocusProvider);
    }

    final pickedDayId = ref.read(pickedNextSessionProvider).value;

    if (pickedDayId == splitDayId) {
      await ref.read(pickedNextSessionProvider.notifier).consumeId();
    }
  }

  Future<void> reorderSplitDays(
    int oldIndex,
    int newIndex,
    String splitDayid,
  ) async {
    final currentDays = state.value;

    if (currentDays == null || currentDays.isEmpty) return;

    if (oldIndex < 0 ||
        oldIndex > currentDays.length ||
        newIndex < 0 ||
        newIndex > currentDays.length) {
      throw RangeError('Invalid split day reorder index.');
    }

    if (currentDays[oldIndex].id != splitDayid) {
      throw StateError('The split day no longer matches the UI index.');
    }

    if (newIndex > oldIndex) newIndex--;

    final reorderedDays = [...currentDays];
    final movedDay = reorderedDays.removeAt(oldIndex);
    reorderedDays.insert(newIndex, movedDay);

    final normalizedDays = [
      for (int i = 0; i < reorderedDays.length; i++)
        SplitDay(
          name: reorderedDays[i].name,
          orderIndex: i,
          id: reorderedDays[i].id,
        ),
    ];

    state = AsyncData(normalizedDays);

    final db = await AppDatabase.getDatabase();

    try {
      await db.transaction((txn) async {
        for (int i = 0; i < normalizedDays.length; i++) {
          final updatedRows = await txn.rawUpdate(
            '''
              UPDATE split_days
              SET order_idx = ?
              WHERE id = ? AND split_id = ?
              ''',
            [i, normalizedDays[i].id, splitId],
          );

          if (updatedRows != 1) {
            throw StateError(
              'Could not reorder split day ${normalizedDays[i].id}',
            );
          }
        }
      });
    } catch (_) {
      state = AsyncData(currentDays);
      rethrow;
    }

    ref.invalidate(presetSplitVmProvider);

    final activeSplitId = await ref.read(activeSplitIdProvider.future);

    if (activeSplitId == splitId) {
      ref.invalidate(workoutFocusProvider);
    }
  }

  Future<void> createNewDay() async {
    final currentDays = state.value;

    if (currentDays == null) {
      throw StateError('Split days are not loaded.');
    }

    final int newDayIndex = currentDays.length;

    final newDay = SplitDay(
      name: 'Day ${newDayIndex + 1}',
      orderIndex: newDayIndex,
    );

    final db = await AppDatabase.getDatabase();

    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
            INSERT INTO split_days(id, split_id, name, order_idx)
            VALUES (?, ?, ?, ?)
            ''',
        [newDay.id, splitId, newDay.name, newDay.orderIndex],
      );
    });

    state = AsyncData([...currentDays, newDay]);

    ref.invalidate(splitPlanProvider(splitId));
    ref.invalidate(presetSplitVmProvider);

    final activeSplitId = await ref.read(activeSplitIdProvider.future);

    if (activeSplitId == splitId) {
      ref.invalidate(workoutFocusProvider);
    }
  }
}
