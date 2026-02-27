import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class AppDatabases {
  static sql.Database? _db;

  static const _presetExercises = <Map<String, Object?>>[
    // Abs
    {'id': 'crunches', 'name': 'Crunches', 'muscle_group': 'abs'},
    {'id': 'leg_raises', 'name': 'Leg Raises', 'muscle_group': 'abs'},

    // Back
    {'id': 'assisted_chin_up', 'name': 'Assisted Chin Up', 'muscle_group': 'back'},
    {'id': 'assisted_pull_up', 'name': 'Assisted Pull Up', 'muscle_group': 'back'},
    {'id': 'barbell_row', 'name': 'Barbell Row', 'muscle_group': 'back'},
    {'id': 'cable_row', 'name': 'Cable Row', 'muscle_group': 'back'},
    {'id': 'chin_up', 'name': 'Chin Up', 'muscle_group': 'back'},
    {'id': 'deadlift', 'name': 'Deadlift', 'muscle_group': 'back'},
    {'id': 'dumbbell_row', 'name': 'Dumbbell Row', 'muscle_group': 'back'},
    {'id': 'hyperextensions', 'name': 'Hyperextensions', 'muscle_group': 'back'},
    {'id': 'pull_up', 'name': 'Pull Up', 'muscle_group': 'back'},
    {'id': 'pulldowns', 'name': 'Pulldowns', 'muscle_group': 'back'},

    // Biceps
    {'id': 'barbell_bicep_curl', 'name': 'Barbell Bicep Curl', 'muscle_group': 'biceps'},
    {'id': 'concentration_curl', 'name': 'Concentration Curl', 'muscle_group': 'biceps'},
    {'id': 'dumbbell_bicep_curl', 'name': 'Dumbbell Bicep Curl', 'muscle_group': 'biceps'},
    {'id': 'hammer_curl', 'name': 'Hammer Curl', 'muscle_group': 'biceps'},

    // Cardio
    {'id': 'cycling', 'name': 'Cycling', 'muscle_group': 'cardio'},
    {'id': 'elliptical_trainer', 'name': 'Elliptical Trainer', 'muscle_group': 'cardio'},
    {'id': 'rowing_machine', 'name': 'Rowing Machine', 'muscle_group': 'cardio'},
    {'id': 'running', 'name': 'Running', 'muscle_group': 'cardio'},
    {'id': 'treadmill', 'name': 'Treadmill', 'muscle_group': 'cardio'},
    {'id': 'walking', 'name': 'Walking', 'muscle_group': 'cardio'},

    // Chest
    {'id': 'bench_press', 'name': 'Bench Press', 'muscle_group': 'chest'},
    {'id': 'cable_crossovers', 'name': 'Cable Crossovers', 'muscle_group': 'chest'},
    {'id': 'dumbbell_press', 'name': 'Dumbbell Press', 'muscle_group': 'chest'},
    {'id': 'dumbbell_flies', 'name': 'Dumbbell flies', 'muscle_group': 'chest'},
    {'id': 'incline_bench_press', 'name': 'Incline Bench Press', 'muscle_group': 'chest'},
    {'id': 'incline_dumbbell_press', 'name': 'Incline Dumbbell Press', 'muscle_group': 'chest'},

    // Legs
    {'id': 'calf_raises', 'name': 'Calf Raises', 'muscle_group': 'legs'},
    {'id': 'front_squat', 'name': 'Front Squat', 'muscle_group': 'legs'},
    {'id': 'leg_curls', 'name': 'Leg Curls', 'muscle_group': 'legs'},
    {'id': 'leg_extensions', 'name': 'Leg Extensions', 'muscle_group': 'legs'},
    {'id': 'leg_press', 'name': 'Leg Press', 'muscle_group': 'legs'},
    {'id': 'lunges', 'name': 'Lunges', 'muscle_group': 'legs'},
    {'id': 'seated_calf_raises', 'name': 'Seated Calf Raises', 'muscle_group': 'legs'},
    {'id': 'squat', 'name': 'Squat', 'muscle_group': 'legs'},
    {'id': 'straight_leg_deadlifts', 'name': 'Straight Leg Deadlifts', 'muscle_group': 'legs'},

    // Shoulders
    {'id': 'dumbbell_lateral_raises', 'name': 'Dumbbell Lateral Raises', 'muscle_group': 'shoulders'},
    {'id': 'military_press', 'name': 'Military Press', 'muscle_group': 'shoulders'},
    {'id': 'shoulder_dumbbell_press', 'name': 'Shoulder Dumbbell Press', 'muscle_group': 'shoulders'},
    {'id': 'upright_rows', 'name': 'Upright Rows', 'muscle_group': 'shoulders'},

    // Triceps
    {'id': 'assisted_dips', 'name': 'Assisted Dips', 'muscle_group': 'triceps'},
    {'id': 'close_grip_bench_press', 'name': 'Close Grip Bench Press', 'muscle_group': 'triceps'},
    {'id': 'dips', 'name': 'Dips', 'muscle_group': 'triceps'},
    {'id': 'pushdowns', 'name': 'Pushdowns', 'muscle_group': 'triceps'},
    {'id': 'triceps_extensions', 'name': 'Triceps Extensions', 'muscle_group': 'triceps'},
  ];

  static Future<sql.Database> getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await sql.getDatabasesPath();

    _db = await sql.openDatabase(
      path.join(dbPath, 'lifting.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE split_plan(id TEXT PRIMARY KEY, name TEXT, order_idx INT, is_selected_preset TEXT)',
        );
        await db.execute(
          'CREATE TABLE exercises(id TEXT PRIMARY KEY, name TEXT, muscle_group TEXT)',
        );
        await db.execute(
          'CREATE TABLE day_exercises(day_id TEXT, exercise_id TEXT, order_idx INT)',
        );

        final batch = db.batch();
        for (final ex in _presetExercises) {
          batch.insert('exercises', ex);
        }
        await batch.commit(noResult: true);
      },
    );

    return _db!;
  }
}