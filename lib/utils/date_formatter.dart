import 'package:intl/intl.dart';

class DateFormatter {
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  static String dateTime(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  static String dateOnly(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat.MMMd().format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  static String dayOfWeek(DateTime date) {
    return DateFormat.EEEE().format(date);
  }

  static String careDue(DateTime? date) {
    if (date == null) return 'Not scheduled';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }
}
