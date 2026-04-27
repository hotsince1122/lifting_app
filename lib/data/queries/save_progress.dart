import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';

Future<bool> saveSetCellToDb(
  int activeSessionSetId,
  double? weight,
  int? reps,
  String? notes,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    final rowsUpdated = await db.transaction((txn) async {
      final rowsUpdated = await txn.rawUpdate(
        '''
      UPDATE active_session_sets
      SET actual_weight = ?,
        actual_repetitions = ?,
        actual_notes = ?
      WHERE id = ?
      ''',
        [weight, reps, notes, activeSessionSetId],
      );

      return rowsUpdated;
    });

    if (rowsUpdated == 1) {
      return true;
    } else {
      return false;
    }
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
    return false;
  }
}
