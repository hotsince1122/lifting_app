import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:sqflite/sqflite.dart';

List<Exercise> _addDefaultSetToExercisesIfEmpty(
  List<Exercise> exercisesPlanned,
) {
  for (int i = 0; i < exercisesPlanned.length; i++) {
    if (exercisesPlanned[i].sets.isEmpty) {
      exercisesPlanned[i].sets.add(
        TrainingSet(
          setIndex: 1,
          hintRepetitions: 0,
          hintWeight: 0,
          hintNotes: '',
        ),
      );
    }
  }

  return exercisesPlanned;
}

List<Exercise> _addSetsToExerciseFromDbData(
  List<Exercise> exercisesPlanned,
  List<Map<String, Object?>> data, {
  bool isSessionAlreadyActive = false,
}) {
  if (data.isEmpty) return exercisesPlanned;

  for (final set in data) {
    for (int i = 0; i < exercisesPlanned.length; i++) {
      if (exercisesPlanned[i].id == set['exerciseId'] as String &&
          exercisesPlanned[i].orderIndex == set['orderIndex'] as int) {
        exercisesPlanned[i].sets.add(
          TrainingSet(
            activeSessionSetId: set['activeSessionSetId'] as int?,
            setIndex: set['setIndex'] as int,
            hintRepetitions: set['hintRepetitions'] as int,
            hintWeight: (set['hintWeight'] as num).toDouble(),
            hintNotes: set['hintNotes'] as String? ?? '',

            actualRepetitions: isSessionAlreadyActive
                ? set['actualRepetitions'] as int?
                : null,
            actualWeight: isSessionAlreadyActive
                ? (set['actualWeight'] as num?)?.toDouble()
                : null,
            actualNotes: isSessionAlreadyActive
                ? set['actualNotes'] as String?
                : null,
          ),
        );
      }
    }
  }

  return exercisesPlanned;
}

Future<void> populateActiveSessionSets(
  List<Exercise> exercisesPlanned,
  DatabaseExecutor db,
  int sessionId,
) async {
  final batch = db.batch();

  for (final exercise in exercisesPlanned) {
    for (int i = 0; i < exercise.sets.length; i++) {
      final set = exercise.sets[i];

      batch.insert('active_session_sets', ({
        'workout_session_id': sessionId,
        'exercise_id': exercise.id,
        'exercise_order_index': exercise.orderIndex,
        'set_index': set.setIndex ?? i + 1,
        'hint_weight': set.hintWeight,
        'hint_repetitions': set.hintRepetitions,
        'hint_notes': set.hintNotes,
        'is_completed': 0,
        'is_deleted': 0,
      }));
    }
  }

  await batch.commit(noResult: true);
}

Future<int?> loadLastCompletedWorkoutIdForSameDay(
  DatabaseExecutor db,
  int workoutSessionId,
) async {
  final dataLastWorkoutIdWithSameDayId = await db.rawQuery(
    '''
    SELECT id
    FROM workout_sessions
    WHERE day_id = (
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
      )
      AND started_at < (
      SELECT started_at
      FROM workout_sessions
      WHERE id = ?
      )
      AND status = ?
    ORDER BY started_at DESC, id DESC
    LIMIT 1
    ''',
    [
      workoutSessionId,
      workoutSessionId,
      WorkoutSessionStatuses.completedStatus,
    ],
  );

  if (dataLastWorkoutIdWithSameDayId.isEmpty) return null;

  return dataLastWorkoutIdWithSameDayId.first['id'] as int;
}

Future<List<Exercise>> _ifSessionIsAlreadyActiveReturnSets(
  Database db,
  int workoutSessionId,
) async {
  final dataExercises = await db.rawQuery(
    '''
    SELECT e.id AS exerciseId,
      e.name AS exerciseName,
      e.muscle_group AS exerciseMuscleGroup,
      ass.exercise_order_index AS orderIndex
    FROM active_session_sets ass
    JOIN exercises e ON ass.exercise_id = e.id
    WHERE ass.workout_session_id = ?
    GROUP BY exercise_order_index
    ORDER BY ass.exercise_order_index
    ''',
    [workoutSessionId],
  );

  if (dataExercises.isEmpty) return [];

  var currentExercises = <Exercise>[];
  for (final exercise in dataExercises) {
    currentExercises.add(
      Exercise(
        name: exercise['exerciseName'] as String,
        muscleGroup: exercise['exerciseMuscleGroup'] as String,
        id: exercise['exerciseId'] as String,
        orderIndex: exercise['orderIndex'] as int,
      ),
    );
  }

  final dataCurrentSets = await db.rawQuery(
    '''
    SELECT exercise_id AS exerciseId,
      id AS activeSessionSetId,
      exercise_order_index AS orderIndex,
      set_index AS setIndex,
      hint_weight AS hintWeight,
      hint_repetitions AS hintRepetitions,
      hint_notes AS hintNotes,
      actual_weight AS actualWeight,
      actual_repetitions AS actualRepetitions,
      actual_notes AS actualNotes
    FROM active_session_sets 
    WHERE workout_session_id = ? AND is_deleted = 0
    ORDER BY exercise_order_index, set_index
    ''',
    [workoutSessionId],
  );

  currentExercises = _addSetsToExerciseFromDbData(
    currentExercises,
    dataCurrentSets,
    isSessionAlreadyActive: true,
  );

  return currentExercises;
}

Future<List<Exercise>> _loadPlannedExercises(
  Database db,
  int workoutSessionId,
) async {
  final dataAllExercisesInCurrentDay = await db.rawQuery(
    '''
    SELECT e.id AS exerciseId,
      e.name AS exerciseName,
      e.muscle_group AS exerciseMuscleGroup,
      de.order_idx AS exerciseOrderIndex
    FROM workout_sessions ws
    JOIN day_exercises de ON ws.day_id = de.day_id
    JOIN exercises e ON de.exercise_id = e.id
    WHERE ws.id = ?
    ORDER BY de.order_idx
    ''',
    [workoutSessionId],
  );

  if (dataAllExercisesInCurrentDay.isEmpty) return [];

  return dataAllExercisesInCurrentDay
      .map(
        (row) => Exercise(
          id: row['exerciseId'] as String,
          name: row['exerciseName'] as String,
          muscleGroup: row['exerciseMuscleGroup'] as String,
          orderIndex: row['exerciseOrderIndex'] as int,
        ),
      )
      .toList();
}

Future<List<Exercise>> _loadRepetedWorkoutHints(
  Database db,
  List<Exercise> exercisesPlanned,
  int workoutSessionId,
) async {
  final lastWorkoutIdWithSameDayId = await loadLastCompletedWorkoutIdForSameDay(
    db,
    workoutSessionId,
  );

  if (lastWorkoutIdWithSameDayId == null) {
    exercisesPlanned = _addDefaultSetToExercisesIfEmpty(exercisesPlanned);
    return exercisesPlanned;
  }

  final placeholder = buildPlaceholder(exercisesPlanned.length);
  final exercisesPlannedIds = exercisesPlanned
      .map((exercise) => exercise.id)
      .toList();

  final dataLastWorkoutSets = await db.rawQuery(
    '''
    SELECT ls.ex_id AS exerciseId, 
      ls.weight AS hintWeight,
      ls.repetitions AS hintRepetitions,
      ls.notes AS hintNotes,
      ls.set_index AS setIndex,
      ls.order_index AS orderIndex,
      ls.notes AS notes
    FROM workout_sessions ws
    JOIN logged_sets ls ON ws.id = ls.session_id
    WHERE ws.id = ? AND ls.ex_id IN ($placeholder)
    ORDER BY ls.order_index, ls.set_index
    ''',
    [lastWorkoutIdWithSameDayId, ...exercisesPlannedIds],
  );

  exercisesPlanned = _addSetsToExerciseFromDbData(
    exercisesPlanned,
    dataLastWorkoutSets,
  );
  exercisesPlanned = _addDefaultSetToExercisesIfEmpty(exercisesPlanned);

  return exercisesPlanned;
}

Future<List<Exercise>> resumeOrStartRepetedWorkout(int workoutSessionId) async {
  final db = await AppDatabases.getDatabase();

  final currentExercises = await _ifSessionIsAlreadyActiveReturnSets(
    db,
    workoutSessionId,
  );
  if (currentExercises.isNotEmpty) return currentExercises;

  List<Exercise> exercisesPlanned = await _loadPlannedExercises(
    db,
    workoutSessionId,
  );

  if (exercisesPlanned.isEmpty) {
    return [];
  }

  exercisesPlanned = await _loadRepetedWorkoutHints(
    db,
    exercisesPlanned,
    workoutSessionId,
  );

  await populateActiveSessionSets(exercisesPlanned, db, workoutSessionId);

  return _ifSessionIsAlreadyActiveReturnSets(db, workoutSessionId);
}