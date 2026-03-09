String generateId(String type) {
  return '$type-${DateTime.now().millisecondsSinceEpoch}';
}
