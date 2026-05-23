/// Returns true if [v] >= [min] using simple integer-segment comparison.
/// e.g. versionAtLeast("1.1", "1.1") == true
///      versionAtLeast("1.0", "1.1") == false
bool versionAtLeast(String v, String min) {
  final parts = _parse(v);
  final minParts = _parse(min);
  for (int i = 0; i < minParts.length; i++) {
    final a = i < parts.length ? parts[i] : 0;
    final b = minParts[i];
    if (a < b) return false;
    if (a > b) return true;
  }
  return true;
}

List<int> _parse(String v) =>
    v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
