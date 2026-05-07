const _copyWithSentinel = Object();

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

  TrainingSet copyWith({
    Object? activeSessionSetId = _copyWithSentinel,
    Object? setIndex = _copyWithSentinel,
    Object? isWarmup = _copyWithSentinel,
    double? hintWeight,
    int? hintRepetitions,
    String? hintNotes,
    Object? actualWeight = _copyWithSentinel,
    Object? actualRepetitions = _copyWithSentinel,
    Object? actualNotes = _copyWithSentinel,
  }) {
    return TrainingSet(
      activeSessionSetId:
          identical(activeSessionSetId, _copyWithSentinel)
          ? this.activeSessionSetId
          : activeSessionSetId as int?,
      setIndex: identical(setIndex, _copyWithSentinel)
          ? this.setIndex
          : setIndex as int?,
      isWarmup: identical(isWarmup, _copyWithSentinel)
          ? this.isWarmup
          : isWarmup as bool?,
      hintWeight: hintWeight ?? this.hintWeight,
      hintRepetitions: hintRepetitions ?? this.hintRepetitions,
      hintNotes: hintNotes ?? this.hintNotes,
      actualWeight: identical(actualWeight, _copyWithSentinel)
          ? this.actualWeight
          : actualWeight as double?,
      actualRepetitions: identical(actualRepetitions, _copyWithSentinel)
          ? this.actualRepetitions
          : actualRepetitions as int?,
      actualNotes: identical(actualNotes, _copyWithSentinel)
          ? this.actualNotes
          : actualNotes as String?,
    );
  }
}
