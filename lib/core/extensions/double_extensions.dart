extension DoubleFormatting on double {
  String get formatted =>
      this == truncateToDouble() ? toStringAsFixed(0) : toString();
}
