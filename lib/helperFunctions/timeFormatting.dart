import 'package:flutter/material.dart';

TimeOfDay parseTime(String timeStr) {
  final format =
      RegExp(r'(\d+):(\d+) (AM|PM)'); // Extracts hour, minute, and AM/PM
  final match = format.firstMatch(timeStr);

  if (match == null) return TimeOfDay.now(); // Default fallback

  int hour = int.parse(match.group(1)!);
  int minute = int.parse(match.group(2)!);
  String period = match.group(3)!;

  if (period == "PM" && hour != 12) hour += 12;
  if (period == "AM" && hour == 12) hour = 0;

  return TimeOfDay(hour: hour, minute: minute);
}

String formatTime(TimeOfDay time) {
  final int hour =
      time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod; // Convert 0 to 12
  final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
  final String minute =
      time.minute.toString().padLeft(2, '0'); // Ensure 2 digits

  return '$hour:$minute $period';
}

String formatStoredTime(String timeStr) {
  try {
    List<String> parts = timeStr.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
    return formatTime(time); // Use your existing _formatTime function
  } catch (e) {
    return timeStr; // Return original in case of an error
  }
}

bool isClosingTimeValid(TimeOfDay opening, TimeOfDay closing) {
  return (closing.hour > opening.hour) ||
      (closing.hour == opening.hour && closing.minute > opening.minute);
}
