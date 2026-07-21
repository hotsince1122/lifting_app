import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/providers/persisted/split_plan.dart';

final splitNameProvider = AsyncNotifierProvider.autoDispose
    .family<SplitNameNotifier, String, int>(SplitNameNotifier.new);

class SplitNameNotifier extends AsyncNotifier<String> {
  SplitNameNotifier(this.splitId);

  final int splitId;

  @override
  Future<String> build() async {

    final db = await AppDatabases.getDatabase();

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

  Future<void> renameSplit (String newName) async {
    final db = await AppDatabases.getDatabase();

    await db.rawUpdate(
      '''
      UPDATE split_plans
      SET name = ?
      WHERE id =?
      ''', [newName, splitId]
    );

    ref.invalidate(splitPlanProvider(splitId));

    state = AsyncData(newName);
  }
}