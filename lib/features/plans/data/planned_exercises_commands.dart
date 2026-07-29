import 'package:lifting_tracker_app/core/database/app_database.dart';

Future<void> addExerciseToDay({
  required String dayId,
  required String exerciseId,
}) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawInsert(
      '''
        INSERT INTO day_exercises(day_id, exercise_id, order_idx)
        VALUES (
          ?,
          ?,
          COALESCE((
            SELECT MAX(order_idx) + 1
            FROM day_exercises
            WHERE day_id = ?
          ), 0)
        )
        ''',
      [dayId, exerciseId, dayId],
    );
  });
}

Future<void> deleteExerciseFromDay(int relationId) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.delete('day_exercises', where: 'id = ?', whereArgs: [relationId]);
  });
}

Future<void> reorderExercises(List<int> orderedRelationIds) async {
  if (orderedRelationIds.isEmpty) return;

  final db = await AppDatabase.getDatabase();
  final caseParts = <String>[
    for (int i = 0; i < orderedRelationIds.length; i++)
      'WHEN ${orderedRelationIds[i]} THEN $i',
  ];
  final placeholders = List.filled(orderedRelationIds.length, '?').join(', ');

  await db.transaction((txn) async {
    await txn.rawUpdate('''
        UPDATE day_exercises
        SET order_idx = CASE id
          ${caseParts.join('\n          ')}
        END
        WHERE id IN ($placeholders)
        ''', orderedRelationIds);
  });
}

Future<void> replacePlannedExercises(
  String dayId,
  List<String> exerciseIds,
) async {
  final db = await AppDatabase.getDatabase();

  await db.transaction((txn) async {
    await txn.rawDelete(
      '''
        DELETE FROM day_exercises
        WHERE day_id = ?
        ''',
      [dayId],
    );

    final batch = txn.batch();
    for (int orderIndex = 0; orderIndex < exerciseIds.length; orderIndex++) {
      batch.insert('day_exercises', {
        'day_id': dayId,
        'exercise_id': exerciseIds[orderIndex],
        'order_idx': orderIndex,
      });
    }
    await batch.commit(noResult: true);
  });
}
