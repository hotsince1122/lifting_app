import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/exercises/data/actions_on_exercise_catalog.dart'
    as db_actions;
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';

final exerciseByMuscleGroupProvider =
    AsyncNotifierProvider.family<
      ExerciseByMuscleGroupController,
      List<CatalogExercise>,
      String
    >(ExerciseByMuscleGroupController.new);

class ExerciseByMuscleGroupController
    extends AsyncNotifier<List<CatalogExercise>> {
  ExerciseByMuscleGroupController(this.muscleGroup);

  final String muscleGroup;

  @override
  FutureOr<List<CatalogExercise>> build() {
    return db_actions.loadExercisesByMuscleGroup(muscleGroup);
  }

  Future<CatalogExercise> addCustomExercise(
    String name,
    String muscleGroup,
  ) async {
    final newExercise = CatalogExercise(name: name, muscleGroup: muscleGroup);

    await db_actions.insertExercise(newExercise);

    state = AsyncData(
      await db_actions.loadExercisesByMuscleGroup(this.muscleGroup),
    );
    return newExercise;
  }

  Future<void> updateExercise(
    CatalogExercise exercise,
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

    state = AsyncData(await db_actions.loadExercisesByMuscleGroup(muscleGroup));
  }
}
