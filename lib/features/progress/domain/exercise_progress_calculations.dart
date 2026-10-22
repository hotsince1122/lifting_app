import 'package:lifting_tracker_app/features/progress/domain/exercise_progress_set.dart';

List<ExerciseProgressSet> maxWeightSetBySession(
  List<ExerciseProgressSet> sets,
) {
  List<ExerciseProgressSet> maxWeightSets = <ExerciseProgressSet>[];

  if (sets.isEmpty) return [];

  var bestSet = sets.first;

  for (int i = 1; i < sets.length; i++) {
    if (bestSet.sessionId == sets[i].sessionId) {
      if (bestSet.weight < sets[i].weight) {
        bestSet = sets[i];
      }
    } else {
      maxWeightSets.add(bestSet);
      bestSet = sets[i];
    }
  }

  maxWeightSets.add(bestSet);

  return maxWeightSets;
}

List<ExerciseProgressSet> bestSetBySession(List<ExerciseProgressSet> sets) {
  List<ExerciseProgressSet> weightTimesRepsBestSets = <ExerciseProgressSet>[];

  if (sets.isEmpty) return [];

  var bestSet = sets.first;

  for (int i = 1; i < sets.length; i++) {
    if (bestSet.sessionId == sets[i].sessionId) {
      if (bestSet.weightReps < sets[i].weightReps) {
        bestSet = sets[i];
      }
    } else {
      weightTimesRepsBestSets.add(bestSet);
      bestSet = sets[i];
    }
  }

  weightTimesRepsBestSets.add(bestSet);

  return weightTimesRepsBestSets;
}
