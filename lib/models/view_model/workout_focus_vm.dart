class WorkoutFocusVm {
  const WorkoutFocusVm({
    required this.workoutName,
    required this.muscleGroups,
    required this.nrOfExercises,
    this.isActiveQuickWorkout = false,
  });

  final String workoutName;
  final String? muscleGroups;
  final int? nrOfExercises;
  final bool isActiveQuickWorkout;
}
