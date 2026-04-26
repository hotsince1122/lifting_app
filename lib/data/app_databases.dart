import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class AppDatabases {
  static sql.Database? _db;

  static const _presetSplitPlans = <Map<String, Object?>>[
    {'id': 1, 'name': 'PPL', 'is_preset': 1, 'is_active': 0},
    {'id': 2, 'name': 'UL', 'is_preset': 1, 'is_active': 0},
    {'id': 3, 'name': 'Arnold', 'is_preset': 1, 'is_active': 0},
    {'id': 4, 'name': 'FB', 'is_preset': 1, 'is_active': 0},
  ];

  static const _presetSplitDays = <Map<String, Object?>>[
    {'id': 'ppl_push', 'split_id': 1, 'name': 'Push', 'order_idx': 0},
    {'id': 'ppl_pull', 'split_id': 1, 'name': 'Pull', 'order_idx': 1},
    {'id': 'ppl_legs', 'split_id': 1, 'name': 'Legs', 'order_idx': 2},
    {'id': 'ul_upper', 'split_id': 2, 'name': 'Upper', 'order_idx': 0},
    {'id': 'ul_lower', 'split_id': 2, 'name': 'Lower', 'order_idx': 1},
    {
      'id': 'arnold_chest_back',
      'split_id': 3,
      'name': 'Chest & Back',
      'order_idx': 0,
    },
    {
      'id': 'arnold_shoulders_arms',
      'split_id': 3,
      'name': 'Shoulders & Arms',
      'order_idx': 1,
    },
    {'id': 'arnold_legs', 'split_id': 3, 'name': 'Legs', 'order_idx': 2},
    {'id': 'fb_day1', 'split_id': 4, 'name': 'Day1', 'order_idx': 0},
    {'id': 'fb_day2', 'split_id': 4, 'name': 'Day2', 'order_idx': 1},
    {'id': 'fb_day3', 'split_id': 4, 'name': 'Day3', 'order_idx': 2},
  ];

  static const _presetExercises = <Map<String, Object?>>[
    // Abs
    {'id': 'crunches', 'name': 'Crunches', 'muscle_group': 'abs'},
    {'id': 'leg_raises', 'name': 'Leg Raises', 'muscle_group': 'abs'},

    // Back
    {
      'id': 'assisted_chin_up',
      'name': 'Assisted Chin Up',
      'muscle_group': 'back',
    },
    {
      'id': 'assisted_pull_up',
      'name': 'Assisted Pull Up',
      'muscle_group': 'back',
    },
    {'id': 'barbell_row', 'name': 'Barbell Row', 'muscle_group': 'back'},
    {'id': 'cable_row', 'name': 'Cable Row', 'muscle_group': 'back'},
    {'id': 'chin_up', 'name': 'Chin Up', 'muscle_group': 'back'},
    {'id': 'deadlift', 'name': 'Deadlift', 'muscle_group': 'back'},
    {'id': 'dumbbell_row', 'name': 'Dumbbell Row', 'muscle_group': 'back'},
    {
      'id': 'hyperextensions',
      'name': 'Hyperextensions',
      'muscle_group': 'back',
    },
    {'id': 'pull_up', 'name': 'Pull Up', 'muscle_group': 'back'},
    {'id': 'pulldowns', 'name': 'Pulldowns', 'muscle_group': 'back'},

    // Biceps
    {
      'id': 'barbell_bicep_curl',
      'name': 'Barbell Bicep Curl',
      'muscle_group': 'biceps',
    },
    {
      'id': 'concentration_curl',
      'name': 'Concentration Curl',
      'muscle_group': 'biceps',
    },
    {
      'id': 'dumbbell_bicep_curl',
      'name': 'Dumbbell Bicep Curl',
      'muscle_group': 'biceps',
    },
    {'id': 'hammer_curl', 'name': 'Hammer Curl', 'muscle_group': 'biceps'},

    // Cardio
    {'id': 'cycling', 'name': 'Cycling', 'muscle_group': 'cardio'},
    {
      'id': 'elliptical_trainer',
      'name': 'Elliptical Trainer',
      'muscle_group': 'cardio',
    },
    {
      'id': 'rowing_machine',
      'name': 'Rowing Machine',
      'muscle_group': 'cardio',
    },
    {'id': 'running', 'name': 'Running', 'muscle_group': 'cardio'},
    {'id': 'treadmill', 'name': 'Treadmill', 'muscle_group': 'cardio'},
    {'id': 'walking', 'name': 'Walking', 'muscle_group': 'cardio'},

    // Chest
    {'id': 'bench_press', 'name': 'Bench Press', 'muscle_group': 'chest'},
    {
      'id': 'cable_crossovers',
      'name': 'Cable Crossovers',
      'muscle_group': 'chest',
    },
    {'id': 'dumbbell_press', 'name': 'Dumbbell Press', 'muscle_group': 'chest'},
    {'id': 'dumbbell_flies', 'name': 'Dumbbell flies', 'muscle_group': 'chest'},
    {
      'id': 'incline_bench_press',
      'name': 'Incline Bench Press',
      'muscle_group': 'chest',
    },
    {
      'id': 'incline_dumbbell_press',
      'name': 'Incline Dumbbell Press',
      'muscle_group': 'chest',
    },

    // Legs
    {'id': 'calf_raises', 'name': 'Calf Raises', 'muscle_group': 'legs'},
    {'id': 'front_squat', 'name': 'Front Squat', 'muscle_group': 'legs'},
    {'id': 'leg_curls', 'name': 'Leg Curls', 'muscle_group': 'legs'},
    {'id': 'leg_extensions', 'name': 'Leg Extensions', 'muscle_group': 'legs'},
    {'id': 'leg_press', 'name': 'Leg Press', 'muscle_group': 'legs'},
    {'id': 'lunges', 'name': 'Lunges', 'muscle_group': 'legs'},
    {
      'id': 'seated_calf_raises',
      'name': 'Seated Calf Raises',
      'muscle_group': 'legs',
    },
    {'id': 'squat', 'name': 'Squat', 'muscle_group': 'legs'},
    {
      'id': 'straight_leg_deadlifts',
      'name': 'Straight Leg Deadlifts',
      'muscle_group': 'legs',
    },

    // Shoulders
    {
      'id': 'dumbbell_lateral_raises',
      'name': 'Dumbbell Lateral Raises',
      'muscle_group': 'shoulders',
    },
    {
      'id': 'military_press',
      'name': 'Military Press',
      'muscle_group': 'shoulders',
    },
    {
      'id': 'shoulder_dumbbell_press',
      'name': 'Shoulder Dumbbell Press',
      'muscle_group': 'shoulders',
    },
    {'id': 'upright_rows', 'name': 'Upright Rows', 'muscle_group': 'shoulders'},

    // Triceps
    {'id': 'assisted_dips', 'name': 'Assisted Dips', 'muscle_group': 'triceps'},
    {
      'id': 'close_grip_bench_press',
      'name': 'Close Grip Bench Press',
      'muscle_group': 'triceps',
    },
    {'id': 'dips', 'name': 'Dips', 'muscle_group': 'triceps'},
    {'id': 'pushdowns', 'name': 'Pushdowns', 'muscle_group': 'triceps'},
    {
      'id': 'triceps_extensions',
      'name': 'Triceps Extensions',
      'muscle_group': 'triceps',
    },
  ];

  static Future<sql.Database> getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await sql.getDatabasesPath();

    // final fullPath = path.join(dbPath, 'lifting.db');
    // await sql.deleteDatabase(fullPath);

    _db = await sql.openDatabase(
      path.join(dbPath, 'lifting.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE split_plans(
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          is_preset INTEGER NOT NULL,
          is_active INTEGER NOT NULL
          )
          ''');

        await db.execute('''
          CREATE TABLE split_days(
          id TEXT PRIMARY KEY,
          split_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          order_idx INTEGER NOT NULL,
          FOREIGN KEY (split_id) REFERENCES split_plans(id)
          )
          ''');
        await db.execute(
          'CREATE TABLE exercises(id TEXT PRIMARY KEY, name TEXT, muscle_group TEXT)',
        );
        await db.execute('''
          CREATE TABLE day_exercises(
            id INTEGER PRIMARY KEY,
            day_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            order_idx INT,
            FOREIGN KEY (day_id) REFERENCES split_days(id),
            FOREIGN KEY (exercise_id) REFERENCES exercises(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_sessions(
            id INTEGER PRIMARY KEY,
            day_id TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            finished_at INTEGER,
            duration_seconds INTEGER,
            cycle_index INTEGER NOT NULL,
            status TEXT NOT NULL,
            FOREIGN KEY (day_id) REFERENCES split_days(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE logged_sets(
            id INTEGER PRIMARY KEY,
            ex_id TEXT NOT NULL,
            session_id INTEGER NOT NULL,
            weight REAL NOT NULL,
            repetitions INTEGER NOT NULL,
            notes TEXT,
            set_index INTEGER NOT NULL,
            order_index INTEGER NOT NULL,
            FOREIGN KEY (ex_id) REFERENCES exercises(id),
            FOREIGN KEY (session_id) REFERENCES workout_sessions(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE active_session_sets(
            id INTEGER PRIMARY KEY,
            workout_session_id INTEGER NOT NULL,
            exercise_id TEXT NOT NULL,
            exercise_order_index INTEGER NOT NULL,
            set_index INTEGER NOT NULL,

            hint_weight REAL,
            hint_repetitions INTEGER,
            hint_notes TEXT,

            actual_weight REAL,
            actual_repetitions INTEGER,
            actual_notes TEXT,

            is_completed INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,

            FOREIGN KEY (workout_session_id) REFERENCES workout_sessions(id),
            FOREIGN KEY (exercise_id) REFERENCES exercises(id),

            UNIQUE(workout_session_id, exercise_order_index, set_index)
          )
        '''
        );

        final batch = db.batch();
        for (final splitPlan in _presetSplitPlans) {
          batch.insert('split_plans', splitPlan);
        }
        for (final splitDay in _presetSplitDays) {
          batch.insert('split_days', splitDay);
        }
        for (final ex in _presetExercises) {
          batch.insert('exercises', ex);
        }
        await batch.commit(noResult: true);
      },
    );

    return _db!;
  }
}