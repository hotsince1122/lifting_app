import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/plans/domain/planned_exercise.dart';

import 'package:lifting_tracker_app/features/plans/data/planned_exercises_queries.dart'
    as queries;

import 'package:lifting_tracker_app/features/plans/data/planned_exercises_commands.dart'
    as commands;

final plannedExercisesProvider =
    AsyncNotifierProvider.family<
      PlannedExercisesController,
      List<PlannedExercise>,
      String
    >(PlannedExercisesController.new);

class PlannedExercisesController extends AsyncNotifier<List<PlannedExercise>> {
  PlannedExercisesController(this.dayId);

  final String dayId;

  @override
  FutureOr<List<PlannedExercise>> build() {
    return queries.loadPlannedExercises(dayId);
  }

  Future<void> addExerciseToDay(String exerciseId) async {
    await commands.addExerciseToDay(dayId: dayId, exerciseId: exerciseId);

    state = AsyncData(await queries.loadPlannedExercises(dayId));
  }

  Future<void> deleteExerciseFromDay(int relationId) async {
    await commands.deleteExerciseFromDay(relationId);

    state = AsyncData(await queries.loadPlannedExercises(dayId));
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    if (newIndex > oldIndex) newIndex--;

    final reordered = [...currentState];
    final movedItem = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedItem);

    final normalized = [
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(orderIndex: i),
    ];

    state = AsyncData(normalized);

    final orderedRelationIds = normalized
        .map((exercise) => exercise.relationId)
        .toList();

    try {
      await commands.reorderExercises(orderedRelationIds);
    } catch (_) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
