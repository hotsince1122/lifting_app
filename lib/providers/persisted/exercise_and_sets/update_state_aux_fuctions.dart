import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';

AsyncValue<List<Exercise>> addExerciseToState(
  List<Exercise> currentState,
  Exercise newExercise,
) {
  final updated = [...currentState, newExercise];
  return AsyncData(updated);
}

AsyncValue<List<Exercise>>? addExerciseSetToState(
  List<Exercise> currentState,
  Exercise exercise,
  TrainingSet newSet,
) {
  final updated = [...currentState];
  final int index = updated.indexWhere(
    (exerciseList) =>
        exerciseList.id == exercise.id &&
        exerciseList.orderIndex == exercise.orderIndex,
  );
  if (index == -1) return null;

  final oldExercise = updated[index];

  final patchedExercise = Exercise(
    id: oldExercise.id,
    name: oldExercise.name,
    muscleGroup: oldExercise.muscleGroup,
    orderIndex: oldExercise.orderIndex,
    note: oldExercise.note,
    idInDayExerciseRelation: oldExercise.idInDayExerciseRelation,
    sets: [...oldExercise.sets, newSet],
  );

  updated[index] = patchedExercise;
  return AsyncData(updated);
}

AsyncValue<List<Exercise>> deleteExerciseFromState(
  List<Exercise> currentState,
  String exerciseId,
  int exerciseOrderIndex,
) {
  final updated = currentState
      .where(
        (exercise) =>
            !(exercise.id == exerciseId &&
                exercise.orderIndex == exerciseOrderIndex),
      )
      .map((exercise) {
        final orderIndex = exercise.orderIndex;

        if (orderIndex != null && orderIndex > exerciseOrderIndex) {
          return Exercise(
            id: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            orderIndex: orderIndex - 1,
            note: exercise.note,
            idInDayExerciseRelation: exercise.idInDayExerciseRelation,
            sets: exercise.sets,
          );
        }

        return exercise;
      })
      .toList();

  return AsyncData(updated);
}

AsyncValue<List<Exercise>> deleteExerciseSetFromState(
  List<Exercise> currentState,
  String exerciseId,
  int exerciseOrderIndex,
  int setIndex,
) {
  final updated = currentState.map((exercise) {
    if (exercise.id == exerciseId &&
        exercise.orderIndex == exerciseOrderIndex) {
      final updatedSets = exercise.sets
          .where((set) => set.setIndex != setIndex)
          .map((set) {
            final currentSetIndex = set.setIndex;

            if (currentSetIndex != null && currentSetIndex > setIndex) {
              return TrainingSet(
                activeSessionSetId: set.activeSessionSetId,
                hintRepetitions: set.hintRepetitions,
                hintWeight: set.hintWeight,
                hintNotes: set.hintNotes,
                actualRepetitions: set.actualRepetitions,
                actualWeight: set.actualWeight,
                actualNotes: set.actualNotes,
                setIndex: currentSetIndex - 1,
              );
            }

            return set;
          })
          .toList();

      return Exercise(
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        id: exercise.id,
        note: exercise.note,
        idInDayExerciseRelation: exercise.idInDayExerciseRelation,
        orderIndex: exercise.orderIndex,
        sets: updatedSets,
      );
    }

    return exercise;
  }).toList();

  return AsyncData(updated);
}

AsyncValue<List<Exercise>> saveSetCellToState(
  List<Exercise> currentState,
  String exerciseId,
  int exerciseOrderIndex,
  int activeSessionSetId,
  int? reps,
  double? weight,
  String? notes
) {
  final updated = currentState.map((exercise) {
    if (exercise.id == exerciseId &&
        exercise.orderIndex == exerciseOrderIndex) {
      final updatedSets = exercise.sets.map((set) {
        if (set.activeSessionSetId != null &&
            activeSessionSetId == set.activeSessionSetId) {
          return TrainingSet(
            activeSessionSetId: set.activeSessionSetId,
            hintRepetitions: set.hintRepetitions,
            hintWeight: set.hintWeight,
            hintNotes: set.hintNotes,
            actualRepetitions: reps,
            actualWeight: weight,
            actualNotes: notes,
            setIndex: set.setIndex,
          );
        }

        return set;
      }).toList();

      return Exercise(
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        id: exercise.id,
        note: exercise.note,
        idInDayExerciseRelation: exercise.idInDayExerciseRelation,
        orderIndex: exercise.orderIndex,
        sets: updatedSets,
      );
    }

    return exercise;
  }).toList();

  return AsyncData(updated);
}
