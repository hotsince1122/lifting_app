import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';

final dayNameProvider = AsyncNotifierProvider.autoDispose
    .family<DayNameController, String, String>(DayNameController.new);

class DayNameController extends AsyncNotifier<String> {
  DayNameController(this.dayId);

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

    ref.invalidate(splitDaysProvider(splitId));

    state = AsyncData(newName);
  }
}
