String formatPrettyDate(DateTime date) {
  final now = DateTime.now();

  // Weekday abbreviation
  final weekday = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday - 1];

  // Month abbreviation
  final month = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ][date.month - 1];

  // Ordinal suffix
  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th'; // 11th, 12th, 13th
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  final day = date.day;
  final suffix = getDaySuffix(day);

  if (date.year == now.year) {
    // Current year → Fri, 20th Jan
    return '$weekday, $day$suffix $month';
  } else {
    // Different year → 20th Jan 2026
    return '$day$suffix $month ${date.year}';
  }
}
