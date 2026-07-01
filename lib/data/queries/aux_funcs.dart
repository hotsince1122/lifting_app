import 'package:sqflite/sqflite.dart';

Future<String?> getWorkoutNameFromWorkoutID(
  DatabaseExecutor db,
  int sourceWorkoutId,
) async {
  final data = await db.rawQuery(
    '''
    SELECT workout_name
    FROM workout_sessions
    WHERE id = ?
    ''',
    [sourceWorkoutId],
  );

  if (data.isEmpty) return null;

  return data.first['workout_name'] as String;
}

Future<String> getWorkoutName (Database db, String dayId) async {
  final data = await db.rawQuery(
    '''
    SELECT name
    FROM split_days
    WHERE id = ?
    ''', [dayId]
  );

  if(data.isEmpty) return '';

  return data.first['name'] as String;
}

Future<int> getWorkoutIndex (Database db, String dayId) async {
  final data = await db.rawQuery(
    '''
    SELECT order_idx
    FROM split_days
    WHERE id = ?
    ''', [dayId]
  );

  if(data.isEmpty) throw '???';

  return data.first['order_idx'] as int;

}