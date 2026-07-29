import 'package:lifting_tracker_app/core/database/app_database.dart';
import 'package:lifting_tracker_app/core/utils/build_placeholder_for_sqlite.dart';
import 'package:lifting_tracker_app/core/utils/read_write_sql_bool.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/plans/data/planned_exercises_queries.dart'
    as plan_queries;
import 'package:lifting_tracker_app/features/plans/domain/planned_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_session_editor_queries.dart'
    as queries;
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';
import 'package:sqflite/sqflite.dart';

List<WorkoutExercise> _addDefaultSetToExercisesIfEmpty(
  List<WorkoutExercise> exercisesPlanned,
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

List<WorkoutExercise> _addSetsToExerciseFromDbData(
  List<WorkoutExercise> exercisesPlanned,
  List<Map<String, Object?>> data, {
  bool includeActualValues = false,
}) {
  if (data.isEmpty) return exercisesPlanned;

  final occurrenceIndexes = _buildExerciseOccurrenceIndexes(exercisesPlanned);
  final updatedExercises = <WorkoutExercise>[];

  for (int i = 0; i < exercisesPlanned.length; i++) {
    final exercise = exercisesPlanned[i];
    final updatedSets = [...exercise.sets];

    for (final set in data) {
      if (exercise.catalogExercise.id == set['exerciseId'] as String &&
          occurrenceIndexes[i] == set['occurrenceIndex'] as int) {
        updatedSets.add(
          TrainingSet(
            workoutSessionSetId: set['workoutSessionSetId'] as int?,
            isWarmup: readSqliteBool(set['isWarmup']),
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

List<int> _buildExerciseOccurrenceIndexes(List<WorkoutExercise> exercises) {
  final occurrenceCounts = <String, int>{};
  final occurrenceIndexes = <int>[];

  for (final exercise in exercises) {
    final exerciseId = exercise.catalogExercise.id;
    final occurrenceIndex = occurrenceCounts[exerciseId] ?? 0;
    occurrenceIndexes.add(occurrenceIndex);
    occurrenceCounts[exerciseId] = occurrenceIndex + 1;
  }

  return occurrenceIndexes;
}

Future<void> populateWorkoutSessionSets(
  List<WorkoutExercise> exercisesPlanned,
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
        'exercise_id': exercise.catalogExercise.id,
        'exercise_order_index': exercise.orderIndex,
        'exercise_occurrence_index': exerciseOccurrenceIndexes[exerciseIndex],
        'set_index': set.setIndex ?? i + 1,
        'is_warmup': writeSqliteBool(set.isWarmup),
        'hint_weight': set.hintWeight,
        'hint_repetitions': set.hintRepetitions,
        'hint_notes': set.hintNotes,
      }));
    }
  }

  await batch.commit(noResult: true);
}

Future<List<WorkoutExercise>> _loadExercisesFromWorkoutSession(
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

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

  final currentExercises = <WorkoutExercise>[];
  for (final exercise in dataExercises) {
    currentExercises.add(
      WorkoutExercise(
        catalogExercise: CatalogExercise(
          name: exercise['exerciseName'] as String,
          muscleGroup: exercise['exerciseMuscleGroup'] as String,
          id: exercise['exerciseId'] as String,
        ),
        sets: const [],
        orderIndex: exercise['orderIndex'] as int,
      ),
    );
  }

  return currentExercises;
}

Future<List<WorkoutExercise>> _loadExistingWorkoutSessionSets(
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

Future<List<PlannedExercise>> _loadPlannedExercisesForWorkoutSession(
  Database db,
  int workoutSessionId,
) async {
  final workoutSessionData = await db.rawQuery(
    '''
      SELECT day_id
      FROM workout_sessions
      WHERE id = ?
    ''',
    [workoutSessionId],
  );

  if (workoutSessionData.isEmpty) return [];

  final dayId = workoutSessionData.first['day_id'] as String?;
  if (dayId == null) return [];

  return plan_queries.loadPlannedExercises(dayId);
}

Future<List<WorkoutExercise>> _loadRepeatedWorkoutHints(
  Database db,
  List<WorkoutExercise> exercisesPlanned,
  int workoutSessionId,
) async {
  final lastWorkoutIdWithSameDayId = await queries
      .loadLastCompletedWorkoutIdForSameDay(db, workoutSessionId);

  if (lastWorkoutIdWithSameDayId == null) {
    exercisesPlanned = _addDefaultSetToExercisesIfEmpty(exercisesPlanned);
    return exercisesPlanned;
  }

  final placeholder = buildPlaceholder(exercisesPlanned.length);
  final exercisesPlannedIds = exercisesPlanned
      .map((exercise) => exercise.catalogExercise.id)
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

Future<List<WorkoutExercise>> loadOrCreateWorkoutSessionEditorSets(
  int workoutSessionId,
) async {
  final db = await AppDatabase.getDatabase();

  final currentExercises = await _loadExistingWorkoutSessionSets(
    db,
    workoutSessionId,
  );
  if (currentExercises.isNotEmpty) return currentExercises;

  final plannedExercises = await _loadPlannedExercisesForWorkoutSession(
    db,
    workoutSessionId,
  );

  if (plannedExercises.isEmpty) {
    return [];
  }

  var workoutExercises = [
    for (final plannedExercise in plannedExercises)
      WorkoutExercise(
        catalogExercise: plannedExercise.catalogExercise,
        sets: const [],
        orderIndex: plannedExercise.orderIndex,
      ),
  ];

  workoutExercises = await _loadRepeatedWorkoutHints(
    db,
    workoutExercises,
    workoutSessionId,
  );

  await populateWorkoutSessionSets(workoutExercises, db, workoutSessionId);

  return _loadExistingWorkoutSessionSets(db, workoutSessionId);
}

Future<List<WorkoutExercise>> loadSetsForEdit(int workoutSessionId) async {
  final db = await AppDatabase.getDatabase();

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

  return _loadExistingWorkoutSessionSets(db, workoutSessionId);
}
