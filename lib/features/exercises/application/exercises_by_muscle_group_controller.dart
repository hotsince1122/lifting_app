import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/exercises/data/exercise_catalog_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/exercises/data/exercise_catalog_queries.dart'
    as queries;
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
    return queries.loadExercisesByMuscleGroup(muscleGroup);
  }

  Future<CatalogExercise> addCustomExercise(
    String name,
    String muscleGroup,
  ) async {
    final newExercise = CatalogExercise(name: name, muscleGroup: muscleGroup);

    await commands.insertExercise(newExercise);

    state = AsyncData(
      await queries.loadExercisesByMuscleGroup(this.muscleGroup),
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

    await commands.updateExercise(updatedExercise);

    state = AsyncData(
      await queries.loadExercisesByMuscleGroup(this.muscleGroup),
    );
  }

  Future<void> deleteExercise(String exerciseId) async {
    await commands.deleteExercise(exerciseId);

    state = AsyncData(await queries.loadExercisesByMuscleGroup(muscleGroup));
  }
}
