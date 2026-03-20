import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/providers/persisted/active_split_plan.dart';

Future<bool> _loadIfUserCanFinishSetup() async {
  final db = await AppDatabases.getDatabase();
  
  var rows = await db.rawQuery(
    '''
    SELECT sd.id
    FROM split_plans sp
    JOIN split_days sd ON sp.id = sd.split_id
    WHERE sp.is_active = 1
    '''
  );

  final List<String> dayIds = rows.map((row) => row['id'] as String).toList();

  if (dayIds.isEmpty) return false;

  final placeholders = List.filled(dayIds.length, '?').join(', ');

  rows = await db.rawQuery('''
    SELECT day_id
    FROM day_exercises
    WHERE day_id IN ($placeholders)
    GROUP BY day_id
    ''', dayIds);

  final returnedDayIds = rows.map((row) => row['day_id'] as String).toSet();

  return returnedDayIds.length == dayIds.length &&
      returnedDayIds.containsAll(dayIds.toSet());
}

final canUserFinishSetupProvider =
    AsyncNotifierProvider<CanUserFinishSetupNotifier, bool>(
      CanUserFinishSetupNotifier.new,
    );

class CanUserFinishSetupNotifier extends AsyncNotifier<bool> {

  @override
  FutureOr<bool> build() {
    ref.watch(activeSplitPlanProvider);
    return _loadIfUserCanFinishSetup();
  }

  Future<void> refresh() async {
    state = AsyncData(await _loadIfUserCanFinishSetup());
  }
}
