import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/split_days.dart';

import 'package:path/path.dart' as path;

import 'package:sqflite/sqflite.dart' as sql;

Future<sql.Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'split_plan.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE split_plan(id TEXT PRIMARY KEY, name TEXT, order_idx INT, is_selected_preset TEXT)',
      );
    },
    version: 1,
  );
  return db;
}

Future<List<SplitDay>> _loadSplitFromDb() async {
  final db = await _getDatabase();
  final data = await db.query('split_plan', orderBy: 'order_idx ASC');

  return data
      .map(
        (row) => SplitDay(
          name: row['name'] as String,
          orderIndex: row['order_idx'] as int,
          id: row['id'] as String,
          selectedPreset: row['is_selected_preset'] as String?,
        ),
      )
      .toList();
}

final splitPlanProvider =
    AsyncNotifierProvider<SplitPlanNotifier, List<SplitDay>>(
      SplitPlanNotifier.new,
    );

class SplitPlanNotifier extends AsyncNotifier<List<SplitDay>> {
  @override
  Future<List<SplitDay>> build() {
    return _loadSplitFromDb();
  }

  Future<void> changeSplit(List<SplitDay> newSplit) async {
    final db = await _getDatabase();

    await db.transaction((txn) async {
      await txn.delete('split_plan');

      for (final splitDay in newSplit) {
        await txn.insert('split_plan', {
          'id': splitDay.id,
          'order_idx': splitDay.orderIndex,
          'name': splitDay.name,
          'is_selected_preset': splitDay.selectedPreset,
        });
      }
    });

    state = AsyncData(newSplit);
  }
}
