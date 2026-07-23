String buildPlaceholder(int length) {
  return List<String>.generate(length, (_) => '?').join(', ');
}