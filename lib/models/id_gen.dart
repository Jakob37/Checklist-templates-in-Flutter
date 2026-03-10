int _idCounter = 0;

String generateId(String type) {
  _idCounter++;
  return '$type-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
}
