const List<String> _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Contoh: "5 Nov 2026".
String formatShortDate(DateTime d) {
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

/// Label pemisah hari pada chat: "Hari ini", "Kemarin", atau tanggal.
String formatDayLabel(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  if (isSameDay(d, today)) return 'Hari ini';
  if (isSameDay(d, today.subtract(const Duration(days: 1)))) return 'Kemarin';
  return formatShortDate(d);
}
