import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';

import 'package:lifting_tracker_app/features/plans/data/split_day_queries.dart'
    as queries;

import 'package:lifting_tracker_app/features/plans/data/split_day_commands.dart'
    as commands;

final dayNameProvider = AsyncNotifierProvider.autoDispose
    .family<DayNameController, String, String>(DayNameController.new);

class DayNameController extends AsyncNotifier<String> {
  DayNameController(this.dayId);

  final String dayId;

  @override
  Future<String> build() async {
    return queries.loadSplitDayName(dayId);
  }

  Future<void> renameDay(String newName) async {
    final splitId = await commands.renameDay(newName, dayId);

    ref.invalidate(splitDaysProvider(splitId));
    state = AsyncData(newName);
  }
}
