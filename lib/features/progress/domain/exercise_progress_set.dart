class ExerciseProgressSet {
  const ExerciseProgressSet({
    required this.setId,
    required this.sessionId,
    required this.sessionStartedAt,
    required this.exerciseOrderIndex,
    required this.setIndex,
    required this.weight,
    required this.repetitions,
  });

  final int setId;
  final int sessionId;
  final DateTime sessionStartedAt;
  final int exerciseOrderIndex;
  final int setIndex;
  final double weight;
  final int repetitions;

  double get weightReps => weight * repetitions;
}
