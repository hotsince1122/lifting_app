class LastCompletedWorkoutSummary {
  const LastCompletedWorkoutSummary({
    required this.workoutName,
    required this.exerciseCount,
    required this.workoutDuration,
  });

  final String workoutName;
  final int exerciseCount;
  final int workoutDuration;
}
