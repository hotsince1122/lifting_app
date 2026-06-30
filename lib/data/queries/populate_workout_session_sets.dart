import 'package:lifting_tracker_app/data/app_databases.dart';
import 'package:lifting_tracker_app/data/queries/aux_functions_for_pop.dart';
import 'package:lifting_tracker_app/data/workout_session_statuses.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:sqflite/sqflite.dart';

bool _readSqliteBool(Object? value) => value == 1 || value == true;

int _writeSqliteBool(bool? value) => value == true ? 1 : 0;

List<Exercise> _addDefaultSetToExercisesIfEmpty(
  List<Exercise> exercisesPlanned,
) {
  return exercisesPlanned.map((exercise) {
    if (exercise.sets.isNotEmpty) return exercise;

    return exercise.copyWith(
      sets: [
        const TrainingSet(
          setIndex: 1,
          isWarmup: false,
          hintRepetitions: 0,
          hintWeight: 0,
          hintNotes: '',
        ),
      ],
    );
  }).toList();
}

List<Exercise> _addSetsToExerciseFromDbData(
  List<Exercise> exercisesPlanned,
  List<Map<String, Object?>> data, {
  bool includeActualValues = false,
}) {
  if (data.isEmpty) return exercisesPlanned;

  final occurrenceIndexes = _buildExerciseOccurrenceIndexes(exercisesPlanned);
  final updatedExercises = <Exercise>[];

  for (int i = 0; i < exercisesPlanned.length; i++) {
    final exercise = exercisesPlanned[i];
    final updatedSets = [...exercise.sets];

    for (final set in data) {
      if (exercise.id == set['exerciseId'] as String &&
          occurrenceIndexes[i] == set['occurrenceIndex'] as int) {
        updatedSets.add(
          TrainingSet(
            workoutSessionSetId: set['workoutSessionSetId'] as int?,
            isWarmup: _readSqliteBool(set['isWarmup']),
            setIndex: set['setIndex'] as int,
            hintRepetitions: set['hintRepetitions'] as int,
            hintWeight: (set['hintWeight'] as num).toDouble(),
            hintNotes: set['hintNotes'] as String? ?? '',
            actualRepetitions: includeActualValues
                ? set['actualRepetitions'] as int?
                : null,
            actualWeight: includeActualValues
                ? (set['actualWeight'] as num?)?.toDouble()
                : null,
            actualNotes: includeActualValues
                ? set['actualNotes'] as String?
                : null,
          ),
        );
      }
    }

    updatedExercises.add(exercise.copyWith(sets: updatedSets));
  }

  return updatedExercises;
}

List<int> _buildExerciseOccurrenceIndexes(List<Exercise> exercises) {
  final occurrenceCounts = <String, int>{};
  final occurrenceIndexes = <int>[];

  for (final exercise in exercises) {
    final occurrenceIndex = occurrenceCounts[exercise.id] ?? 0;
    occurrenceIndexes.add(occurrenceIndex);
    occurrenceCounts[exercise.id] = occurrenceIndex + 1;
  }

  return occurrenceIndexes;
}

Future<void> populateWorkoutSessionSets(
  List<Exercise> exercisesPlanned,
  DatabaseExecutor db,
  int sessionId, {
  int? exerciseOccurrenceIndexOverride,
}) async {
  final batch = db.batch();

  final exerciseOccurrenceIndexes = exerciseOccurrenceIndexOverride == null
      ? _buildExerciseOccurrenceIndexes(exercisesPlanned)
      : List<int>.filled(
          exercisesPlanned.length,
          exerciseOccurrenceIndexOverride,
        );

  for (
    var exerciseIndex = 0;
    exerciseIndex < exercisesPlanned.length;
    exerciseIndex++
  ) {
    final exercise = exercisesPlanned[exerciseIndex];
    for (int i = 0; i < exercise.sets.length; i++) {
      final set = exercise.sets[i];

      batch.insert('active_session_sets', ({
        'workout_session_id': sessionId,
        'exercise_id': exercise.id,
        'exercise_order_index': exercise.orderIndex,
        'exercise_occurrence_index': exerciseOccurrenceIndexes[exerciseIndex],
        'set_index': set.setIndex ?? i + 1,
        'is_warmup': _writeSqliteBool(set.isWarmup),
        'hint_weight': set.hintWeight,
        'hint_repetitions': set.hintRepetitions,
        'hint_notes': set.hintNotes,
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

Future<List<Exercise>> _loadExercisesFromWorkoutSession(
  int workoutSessionId,
) async {
  final db = await AppDatabases.getDatabase();

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

  return currentExercises;
}

Future<List<Exercise>> loadExistingWorkoutSessionSets(
  Database db,
  int workoutSessionId,
) async {
  var currentExercises = await _loadExercisesFromWorkoutSession(
    workoutSessionId,
  );

  final dataCurrentSets = await db.rawQuery(
    '''
    SELECT exercise_id AS exerciseId,
      id AS workoutSessionSetId,
      exercise_order_index AS orderIndex,
      exercise_occurrence_index AS occurrenceIndex,
      is_warmup AS isWarmup,
      set_index AS setIndex,
      hint_weight AS hintWeight,
      hint_repetitions AS hintRepetitions,
      hint_notes AS hintNotes,
      actual_weight AS actualWeight,
      actual_repetitions AS actualRepetitions,
      actual_notes AS actualNotes
    FROM active_session_sets 
    WHERE workout_session_id = ?
    ORDER BY exercise_order_index, set_index
    ''',
    [workoutSessionId],
  );

  currentExercises = _addSetsToExerciseFromDbData(
    currentExercises,
    dataCurrentSets,
    includeActualValues: true,
  );

  return currentExercises;
}

Future<List<Exercise>> loadPlannedExercises(
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

Future<List<String>> loadExercisesExecutedIds(
  Database db,
  int workoutSessionId,
) async {
  final exercisesExecutedIdsData = await db.rawQuery(
    '''
    SELECT exercise_id
    FROM active_session_sets
    WHERE workout_session_id = ?
    GROUP BY exercise_order_index
    ORDER BY exercise_order_index
    ''',
    [workoutSessionId],
  );

  if (exercisesExecutedIdsData.isEmpty) return [];

  return exercisesExecutedIdsData.map((exercise) {
    return exercise['exercise_id'] as String;
  }).toList();
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
      ls.is_warmup AS isWarmup,
      ls.order_index AS orderIndex,
      ls.notes AS notes,
      ls.exercise_occurrence_index AS occurrenceIndex
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

Future<List<Exercise>> loadOrCreateWorkoutSessionEditorSets(
  int workoutSessionId,
) async {
  final db = await AppDatabases.getDatabase();

  final currentExercises = await loadExistingWorkoutSessionSets(
    db,
    workoutSessionId,
  );
  if (currentExercises.isNotEmpty) return currentExercises;

  List<Exercise> exercisesPlanned = await loadPlannedExercises(
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

  await populateWorkoutSessionSets(exercisesPlanned, db, workoutSessionId);

  return loadExistingWorkoutSessionSets(db, workoutSessionId);
}

Future<List<Exercise>> loadSetsForEdit(int workoutSessionId) async {
  final db = await AppDatabases.getDatabase();

  final didPopulateEditDraft = await db.transaction((txn) async {
    final executedExercisesData = await txn.rawQuery(
      '''
        SELECT ls.id AS setId,
          ls.ex_id AS exerciseId,
          ls.weight,
          ls.repetitions,
          ls.notes,
          ls.set_index AS setIndex,
          ls.is_warmup AS isWarmup,
          ls.order_index AS exerciseOrderIndex,
          ls.exercise_occurrence_index AS exerciseOccurrenceIndex,
          e.name AS exerciseName,
          e.muscle_group AS exerciseMuscleGroup
        FROM logged_sets ls
        JOIN exercises e ON e.id = ls.ex_id
        WHERE session_id = ?
        ORDER BY order_index,
          set_index
        ''',
      [workoutSessionId],
    );

    if (executedExercisesData.isEmpty) return false;

    final batch = txn.batch();

    for (final exerciseData in executedExercisesData) {
      batch.insert('active_session_sets', ({
        'workout_session_id': workoutSessionId,
        'exercise_id': exerciseData['exerciseId'] as String,
        'exercise_order_index': exerciseData['exerciseOrderIndex'] as int,
        'exercise_occurrence_index':
            exerciseData['exerciseOccurrenceIndex'] as int,
        'set_index': exerciseData['setIndex'] as int,
        'hint_weight': (exerciseData['weight'] as num).toDouble(),
        'hint_repetitions': exerciseData['repetitions'] as int,
        'hint_notes': exerciseData['notes'] as String? ?? '',
        'actual_weight': (exerciseData['weight'] as num).toDouble(),
        'actual_repetitions': exerciseData['repetitions'] as int,
        'actual_notes': exerciseData['notes'] as String?,
        'is_warmup': exerciseData['isWarmup'] as int,
      }));
    }

    await batch.commit(noResult: true);

    return true;
  });

  if (!didPopulateEditDraft) return [];

  return loadExistingWorkoutSessionSets(db, workoutSessionId);
}
