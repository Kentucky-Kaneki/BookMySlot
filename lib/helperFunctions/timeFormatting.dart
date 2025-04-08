import 'package:intl/intl.dart';

DateTime parseTime(String timeStr) {
  try {
    final format = DateFormat.jm(); // e.g. 2:30 PM
    return format.parse(timeStr);
  } catch (e) {
    return DateTime.now(); // fallback
  }
}

String formatStoredTime(String timeStr) {
  try {
    final timeParts = timeStr.split(':');
    final now = DateTime.now();
    final time = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]),
        int.parse(timeParts[1]));
    return DateFormat.jm().format(time);
  } catch (e) {
    return timeStr;
  }
}
