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

  final patchedExercise = oldExercise.copyWith(
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
          return exercise.copyWith(orderIndex: orderIndex - 1);
        }

        return exercise;
      })
      .toList();

  return AsyncData(updated);
}

AsyncValue<List<Exercise>> replaceExerciseInState(
  List<Exercise> currentState,
  String oldExerciseId,
  int oldExerciseOrderIndex,
  Exercise replacement,
) {
  final updated = currentState.map((exercise) {
    final isExerciseToReplace =
        exercise.id == oldExerciseId &&
        exercise.orderIndex == oldExerciseOrderIndex;

    return isExerciseToReplace ? replacement : exercise;
  }).toList();

  return AsyncData(updated);
}

AsyncValue<List<Exercise>> deleteExerciseSetFromState(
  List<Exercise> currentState,
  int activeSessionSetId,
) {
  final updated = currentState.map((exercise) {
    int? setIndex;
    for (final set in exercise.sets) {
      if (set.activeSessionSetId == activeSessionSetId) {
        setIndex = set.setIndex;
        break;
      }
    }

    if (setIndex != null) {
      final updatedSets = exercise.sets
          .where((set) => set.activeSessionSetId != activeSessionSetId)
          .map((set) {
            final currentSetIndex = set.setIndex;

            if (currentSetIndex != null && currentSetIndex > setIndex!) {
              return set.copyWith(setIndex: currentSetIndex - 1);
            }

            return set;
          })
          .toList();

      return exercise.copyWith(sets: updatedSets);
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
  String? notes,
) {
  final updated = currentState.map((exercise) {
    if (exercise.id == exerciseId &&
        exercise.orderIndex == exerciseOrderIndex) {
      final updatedSets = exercise.sets.map((set) {
        if (set.activeSessionSetId != null &&
            activeSessionSetId == set.activeSessionSetId) {
          return set.copyWith(
            actualRepetitions: reps,
            actualWeight: weight,
            actualNotes: notes,
          );
        }

        return set;
      }).toList();

      return exercise.copyWith(sets: updatedSets);
    }

    return exercise;
  }).toList();

  return AsyncData(updated);
}

AsyncValue<List<Exercise>> toggleSetWarmupInState(
  List<Exercise> currentState,
  int activeSessionSetId,
) {
  final updated = currentState.map((exercise) {
    final updatedSets = exercise.sets.map((set) {
      if (set.activeSessionSetId == activeSessionSetId) {
        return set.copyWith(isWarmup: !(set.isWarmup ?? false));
      }

      return set;
    }).toList();

    return exercise.copyWith(sets: updatedSets);
  }).toList();

  return AsyncData(updated);
}

List<Exercise> reorderExercisesInState(
  List<Exercise> currentState,
  int oldIndex,
  int newIndex,
) {
  if (newIndex > oldIndex) newIndex--;

  final reordered = [...currentState];
  final movedItem = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, movedItem);

  final reorederedFinal = <Exercise>[];

  for (int i = 0; i < reordered.length; i++) {
    reorederedFinal.add(reordered[i].copyWith(orderIndex: i));
  }

  return reorederedFinal;
}
