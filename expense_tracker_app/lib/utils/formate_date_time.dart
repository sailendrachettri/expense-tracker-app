String formatExpenseTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  final isToday =
      now.year == date.year &&
      now.month == date.month &&
      now.day == date.day;

  if (isToday) {
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else {
      return '${difference.inHours} hr ago';
    }
  }

  return '${date.day} ${_monthName(date.month)} · '
         '${_formatTime(date)}';
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

String _formatTime(DateTime date) {
  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final amPm = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute $amPm';
}
