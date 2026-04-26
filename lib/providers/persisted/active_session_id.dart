import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';

FutureOr<int?> _returnActiveSessionId() async {
  final db = await AppDatabases.getDatabase();

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

final activeSessionProvider = AsyncNotifierProvider<ActiveSessionNotifier, int?>(
  ActiveSessionNotifier.new
);

class ActiveSessionNotifier extends AsyncNotifier<int?> {
  @override
  FutureOr<int?> build() {
    ref.watch(currentSessionStatusProvider);
    return _returnActiveSessionId();
  }
}
