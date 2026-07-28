import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/features/plans/application/split_plan_provider.dart';

final splitNameProvider = AsyncNotifierProvider.autoDispose
    .family<SplitNameController, String, int>(SplitNameController.new);

class SplitNameController extends AsyncNotifier<String> {
  SplitNameController(this.splitId);

  final int splitId;

  @override
  Future<String> build() async {
    final db = await AppDatabase.getDatabase();

    final data = await db.rawQuery(
      '''
      SELECT name
      FROM split_plans
      WHERE id = ?
      ''',
      [splitId],
    );

    if (data.isEmpty) {
      throw StateError('Split plan with id $splitId was not found.');
    }

    return data.first['name'] as String;
  }

  Future<void> renameSplit(String newName) async {
    final db = await AppDatabase.getDatabase();

    await db.rawUpdate(
      '''
      UPDATE split_plans
      SET name = ?
      WHERE id =?
      ''',
      [newName, splitId],
    );

    ref.invalidate(splitPlanProvider(splitId));

    state = AsyncData(newName);
  }
}
