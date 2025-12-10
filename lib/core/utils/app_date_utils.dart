import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format TimeOfDay in 24-hour format (HH:mm)
  static String formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMM d', 'en_US').format(dateTime);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Parse duration from total minutes
  static Duration parseDurationFromMinutes(int totalMinutes) {
    return Duration(minutes: totalMinutes);
  }

  /// Format duration from minutes to "Xh Ym" format
  static String formatDurationFromMinutes(int totalMinutes) {
    final duration = parseDurationFromMinutes(totalMinutes);
    return formatDuration(duration);
  }

  static String getDayName(DateTime date) {
    return DateFormat('EEE', 'en_US').format(date);
  }

  /// Get week dates starting from Monday (weekday 1)
  /// Returns 7 DateTime objects: [Monday, Tuesday, ..., Sunday]
  static List<DateTime> getWeekDates(DateTime referenceDate) {
    // Calculate Monday of the week
    // weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    final daysFromMonday = (referenceDate.weekday - 1) % 7;
    final monday = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(Duration(days: daysFromMonday));
    
    // Generate 7 days starting from Monday
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

