import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';

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

Future<void> saveCurrentSessionProgressDb(
  List<Exercise> exercises,
  int workoutSessionId,
) async {
  final db = await AppDatabases.getDatabase();

  try {
    await db.transaction((txn) async {
      for (final exercise in exercises) {
        for (final set in exercise.sets) {
          await txn.insert('logged_sets', {
            'ex_id': exercise.id,
            'session_id': workoutSessionId,
            'weight': set.actualWeight,
            'repetitions': set.actualRepetitions,
            'notes': set.actualNotes,
            'set_index': set.setIndex,
            'order_index': exercise.orderIndex,
          });
        }
      }
    });
  } catch (e, st) {
    debugPrint('Transaction failed: $e');
    debugPrintStack(stackTrace: st);
  }
}
