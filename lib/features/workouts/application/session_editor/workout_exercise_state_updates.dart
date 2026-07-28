import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';

AsyncValue<List<WorkoutExercise>> addExerciseToState(
  List<WorkoutExercise> currentState,
  WorkoutExercise newExercise,
) {
  final updated = [...currentState, newExercise];
  return AsyncData(updated);
}

AsyncValue<List<WorkoutExercise>>? addExerciseSetToState(
  List<WorkoutExercise> currentState,
  WorkoutExercise exercise,
  TrainingSet newSet,
) {
  final updated = [...currentState];
  final int index = updated.indexWhere(
    (exerciseList) =>
        exerciseList.catalogExercise.id == exercise.catalogExercise.id &&
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

AsyncValue<List<WorkoutExercise>> deleteExerciseFromState(
  List<WorkoutExercise> currentState,
  String exerciseId,
  int exerciseOrderIndex,
) {
  final updated = currentState
      .where(
        (exercise) =>
            !(exercise.catalogExercise.id == exerciseId &&
                exercise.orderIndex == exerciseOrderIndex),
      )
      .map((exercise) {
        final orderIndex = exercise.orderIndex;

        if (orderIndex > exerciseOrderIndex) {
          return exercise.copyWith(orderIndex: orderIndex - 1);
        }

        return exercise;
      })
      .toList();

  return AsyncData(updated);
}

AsyncValue<List<WorkoutExercise>> replaceExerciseInState(
  List<WorkoutExercise> currentState,
  String oldExerciseId,
  int oldExerciseOrderIndex,
  WorkoutExercise replacement,
) {
  final updated = currentState.map((exercise) {
    final isExerciseToReplace =
        exercise.catalogExercise.id == oldExerciseId &&
        exercise.orderIndex == oldExerciseOrderIndex;

    return isExerciseToReplace ? replacement : exercise;
  }).toList();

  return AsyncData(updated);
}

AsyncValue<List<WorkoutExercise>> deleteExerciseSetFromState(
  List<WorkoutExercise> currentState,
  int workoutSessionSetId,
) {
  final updated = currentState.map((exercise) {
    int? setIndex;
    for (final set in exercise.sets) {
      if (set.workoutSessionSetId == workoutSessionSetId) {
        setIndex = set.setIndex;
        break;
      }
    }

    if (setIndex != null) {
      final updatedSets = exercise.sets
          .where((set) => set.workoutSessionSetId != workoutSessionSetId)
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

AsyncValue<List<WorkoutExercise>> saveSetCellToState(
  List<WorkoutExercise> currentState,
  String exerciseId,
  int exerciseOrderIndex,
  int workoutSessionSetId,
  int? reps,
  double? weight,
  String? notes,
) {
  final updated = currentState.map((exercise) {
    if (exercise.catalogExercise.id == exerciseId &&
        exercise.orderIndex == exerciseOrderIndex) {
      final updatedSets = exercise.sets.map((set) {
        if (set.workoutSessionSetId != null &&
            workoutSessionSetId == set.workoutSessionSetId) {
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

AsyncValue<List<WorkoutExercise>> toggleSetWarmupInState(
  List<WorkoutExercise> currentState,
  int workoutSessionSetId,
) {
  final updated = currentState.map((exercise) {
    final updatedSets = exercise.sets.map((set) {
      if (set.workoutSessionSetId == workoutSessionSetId) {
        return set.copyWith(isWarmup: !(set.isWarmup ?? false));
      }

      return set;
    }).toList();

    return exercise.copyWith(sets: updatedSets);
  }).toList();

  return AsyncData(updated);
}

List<WorkoutExercise> reorderExercisesInState(
  List<WorkoutExercise> currentState,
  int oldIndex,
  int newIndex,
) {
  if (newIndex > oldIndex) newIndex--;

  final reordered = [...currentState];
  final movedItem = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, movedItem);

  final reorederedFinal = <WorkoutExercise>[];

  for (int i = 0; i < reordered.length; i++) {
    reorederedFinal.add(reordered[i].copyWith(orderIndex: i));
  }

  return reorederedFinal;
}
