class TrainingSet {
  const TrainingSet({
    this.activeSessionSetId,
    this.setIndex,
    this.isWarmup,
    required this.hintRepetitions,
    required this.hintWeight,
    required this.hintNotes,
    this.actualWeight,
    this.actualRepetitions,
    this.actualNotes,
  });

  final int? activeSessionSetId;
  final int? setIndex;
  final bool? isWarmup;

  final double hintWeight;
  final int hintRepetitions;
  final String hintNotes;

  final double? actualWeight;
  final int? actualRepetitions;
  final String? actualNotes;
}
