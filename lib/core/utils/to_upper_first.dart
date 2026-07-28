String toUpperFirst(String label) {
  if (label.isEmpty) return label;
  return label[0].toUpperCase() + label.substring(1);
}
