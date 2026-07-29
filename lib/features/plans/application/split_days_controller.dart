import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/features/plans/application/split_day_summary_controller.dart';

import 'package:lifting_tracker_app/features/plans/data/split_day_queries.dart'
    as queries;

import 'package:lifting_tracker_app/features/plans/data/split_day_commands.dart'
    as commands;

final splitDaysProvider = AsyncNotifierProvider.autoDispose
    .family<SplitDaysController, List<SplitDay>, int>(SplitDaysController.new);

class SplitDaysController extends AsyncNotifier<List<SplitDay>> {
  SplitDaysController(this.splitId);

  final int splitId;

  @override
  FutureOr<List<SplitDay>> build() {
    return queries.loadSplitDays(splitId);
  }

  Future<void> deleteSplitDay(String splitDayId) async {
    await commands.deleteSplitDay(splitId, splitDayId);

    state = AsyncData(await queries.loadSplitDays(splitId));

    ref.invalidate(splitDaySummaryProvider(splitDayId));
  }

  Future<void> reorderSplitDays(
    int oldIndex,
    int newIndex,
    String splitDayid,
  ) async {
    final currentDays = state.value;

    if (currentDays == null || currentDays.isEmpty) return;

    if (oldIndex < 0 ||
        oldIndex >= currentDays.length ||
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

    try {
      await commands.reorderSplitDays(normalizedDays, splitId);
    } catch (_) {
      state = AsyncData(currentDays);
      rethrow;
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

    await commands.createNewDay(newDay, splitId);

    state = AsyncData([...currentDays, newDay]);
  }
}
