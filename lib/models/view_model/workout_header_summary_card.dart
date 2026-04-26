class WorkoutHeaderSummaryCard {
  const WorkoutHeaderSummaryCard({
    required this.workoutName,
    required this.startTime,
    this.endTime,
    this.workoutDurationInMinutes,
  });

  final String workoutName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? workoutDurationInMinutes;
}
