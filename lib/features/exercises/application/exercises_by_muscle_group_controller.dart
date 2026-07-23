import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/exercises/data/actions_on_exercise_catalog.dart'
    as db_actions;
import 'package:lifting_tracker_app/features/exercises/domain/exercise.dart';

final exerciseByMuscleGroupProvider =
    AsyncNotifierProvider.family<
      ExerciseByMuscleGroupController,
      List<Exercise>,
      String
    >(ExerciseByMuscleGroupController.new);

class ExerciseByMuscleGroupController extends AsyncNotifier<List<Exercise>> {
  ExerciseByMuscleGroupController(this.muscleGroup);

  final String muscleGroup;

  @override
  FutureOr<List<Exercise>> build() {
    return db_actions.loadExercisesByMuscleGroup(muscleGroup);
  }

  Future<Exercise> addCustomExercise(String name, String muscleGroup) async {
    final newExercise = Exercise(name: name, muscleGroup: muscleGroup);

    await db_actions.insertExercise(newExercise);

    state = AsyncData(
      await db_actions.loadExercisesByMuscleGroup(this.muscleGroup),
    );
    return newExercise;
  }

  Future<void> updateExercise(
    Exercise exercise,
    String name,
    String muscleGroup,
  ) async {
    final updatedExercise = exercise.copyWith(
      name: name,
      muscleGroup: muscleGroup,
    );

    await db_actions.updateExercise(updatedExercise);

    state = AsyncData(
      await db_actions.loadExercisesByMuscleGroup(this.muscleGroup),
    );
  }

  Future<void> deleteExercise(String exerciseId) async {
    await db_actions.deleteExercise(exerciseId);

    state = AsyncData(
      await db_actions.loadExercisesByMuscleGroup(muscleGroup),
    );
  }
}
