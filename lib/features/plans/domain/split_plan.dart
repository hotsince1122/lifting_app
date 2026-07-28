class SplitPlan {
  const SplitPlan({
    required this.id,
    required this.name,
    required this.isPreset,
    required this.isActive,
    required this.cycleLengthInDays,
    required this.exerciseCount,
  });

  final int id;
  final String name;
  final bool isPreset;
  final bool isActive;
  final int cycleLengthInDays;
  final int exerciseCount;
}
