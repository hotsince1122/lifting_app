import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_session_statuses.dart';
import 'package:lifting_tracker_app/features/workouts/application/active_session_lifecycle_controller.dart';

FutureOr<int?> _returnActiveSessionId() async {
  final db = await AppDatabase.getDatabase();

  final data = await db.rawQuery(
    '''
      SELECT id
      FROM workout_sessions
      WHERE status = ?
      ORDER BY started_at DESC
      LIMIT 1
      ''',
    [WorkoutSessionStatuses.activeStatus],
  );

  if (data.isEmpty) return null;

  final row = data.first;

  return row['id'] as int;
}

final activeSessionIdProvider =
    AsyncNotifierProvider<ActiveSessionIdController, int?>(
      ActiveSessionIdController.new,
    );

class ActiveSessionIdController extends AsyncNotifier<int?> {
  @override
  FutureOr<int?> build() {
    ref.watch(activeSessionLifecycleProvider);
    return _returnActiveSessionId();
  }

  Future<bool> checkIfSessionIsQuick() async {
    if (state.value == null) return false;

    final db = await AppDatabase.getDatabase();

    final data = await db.rawQuery(
      '''
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
      ''',
      [state.value!],
    );

    final row = data.first;

    if (row['day_id'] == null) return true;

    return false;
  }
}
