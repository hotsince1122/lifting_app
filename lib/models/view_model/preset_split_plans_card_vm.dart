class PresetSplitPlanCardVm {
  const PresetSplitPlanCardVm({
    required this.splitId,
    required this.splitPlanName,
    required this.splitDaysNames,
    required this.nrOfDays,
  });

  final int splitId;
  final String splitPlanName;
  final String splitDaysNames;
  final int nrOfDays;
}