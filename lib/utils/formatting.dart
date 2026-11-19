/// Formats a date as `yyyy-MM-dd`.
String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Number of whole calendar days from [date] until today.
int daysSince(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  return today.difference(day).inDays;
}

/// Parses a weight typed by the user. Accepts both "62.5" and "62,5"
/// (Norwegian keyboards use a comma). Returns null when it is not a number.
double? parseWeight(String text) {
  final t = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
  return v;
}

/// Parses a whole number of reps. Returns null when it is not a number.
int? parseReps(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final v = int.tryParse(t);
  if (v == null || v < 0) return null;
  return v;
}

/// Formats a weight without a trailing ".0" (60 instead of 60.0).
String formatWeight(double kg) {
  if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
  final s = kg.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'0+$'), '');
}
