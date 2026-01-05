import '../models/sleep_record_model.dart';

/// Calculates weekly sleep quality score using scientifically validated weighted algorithm
class WeeklySleepQualityCalculator {
  /// Calculate weekly sleep quality score (0-100) based on:
  /// - Sleep Duration (40%)
  /// - Sleep Timing (20%)
  /// - Wake Regularity (20%)
  /// - Restoration (20%)
  static int calculateWeeklyQuality(
    List<SleepRecordModel> weeklyRecords,
    List<SleepRecordModel> allRecords,
  ) {
    if (weeklyRecords.isEmpty) return 0;

    // Filter valid records (with sleep start, wake time, and duration)
    final validRecords = weeklyRecords.where((r) =>
        r.sleepStart != null &&
        r.wakeTime != null &&
        r.durationMinutes > 0).toList();

    if (validRecords.isEmpty) return 0;

    // 1. Sleep Duration Score (40% weight)
    final durationScore = _calculateDurationScore(validRecords) * 0.4;

    // 2. Sleep Timing Score (20% weight)
    final timingScore = _calculateTimingScore(validRecords) * 0.2;

    // 3. Wake Regularity Score (20% weight)
    final wakeRegScore = _calculateWakeRegularityScore(validRecords, allRecords) * 0.2;

    // 4. Restoration Score (20% weight)
    final restScore = _calculateRestorationScore(validRecords) * 0.2;

    // Final score
    final finalScore = (durationScore + timingScore + wakeRegScore + restScore).round();

    return finalScore.clamp(0, 100);
  }

  /// Sleep Duration Score (40% weight)
  /// Ideal: 7-9 hours
  static double _calculateDurationScore(List<SleepRecordModel> records) {
    if (records.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (var record in records) {
      final hours = record.durationMinutes / 60.0;
      double qualityPercent;

      if (hours >= 0 && hours < 4) {
        qualityPercent = 0.0;
      } else if (hours >= 4 && hours < 6) {
        qualityPercent = 40.0;
      } else if (hours >= 6 && hours < 7) {
        qualityPercent = 70.0;
      } else if (hours >= 7 && hours <= 9) {
        qualityPercent = 100.0;
      } else if (hours > 9 && hours <= 10) {
        qualityPercent = 80.0;
      } else {
        // 10h+
        qualityPercent = 60.0;
      }

      totalScore += qualityPercent;
    }

    return totalScore / records.length;
  }

  /// Sleep Timing Score (20% weight)
  /// Rules:
  /// - Before 23:00 = "early" (100% - excellent)
  /// - 23:00-00:00 = "normal" (100% - ideal)
  /// - After 00:00 = "late" (decreasing score)
  static double _calculateTimingScore(List<SleepRecordModel> records) {
    if (records.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (var record in records) {
      if (record.sleepStart == null) continue;

      final hour = record.sleepStart!.hour;
      double timingPercent;

      // Before 23:00 = early (excellent) → 100%
      if (hour < 23) {
        timingPercent = 100.0;
      } 
      // 23:00-00:00 = normal (ideal) → 100%
      else if (hour == 23 || hour == 0) {
        timingPercent = 100.0;
      } 
      // 01:00 = late but acceptable → 80%
      else if (hour == 1) {
        timingPercent = 80.0;
      } 
      // 02:00 = very late → 60%
      else if (hour == 2) {
        timingPercent = 60.0;
      } 
      // 03:00 = extremely late → 40%
      else if (hour == 3) {
        timingPercent = 40.0;
      } 
      // 04:00+ = extremely late → 20%
      else {
        timingPercent = 20.0;
      }

      totalScore += timingPercent;
    }

    return totalScore / records.length;
  }

  /// Wake Regularity Score (20% weight)
  /// Compares each day's wake time to weekly average
  static double _calculateWakeRegularityScore(
    List<SleepRecordModel> weeklyRecords,
    List<SleepRecordModel> allRecords,
  ) {
    if (weeklyRecords.isEmpty) return 0.0;

    // Calculate weekly average wake time
    final validAllRecords = allRecords.where((r) => r.wakeTime != null).toList();
    if (validAllRecords.isEmpty) return 0.0;

    int totalMinutes = 0;
    for (var record in validAllRecords) {
      totalMinutes += record.wakeTime!.hour * 60 + record.wakeTime!.minute;
    }
    final avgWakeMinutes = totalMinutes ~/ validAllRecords.length;

    // Calculate regularity score for each day
    double totalScore = 0.0;
    int count = 0;

    for (var record in weeklyRecords) {
      if (record.wakeTime == null) continue;

      final wakeMinutes = record.wakeTime!.hour * 60 + record.wakeTime!.minute;
      final difference = (wakeMinutes - avgWakeMinutes).abs();

      double regPercent;
      if (difference < 20) {
        regPercent = 100.0;
      } else if (difference < 40) {
        regPercent = 80.0;
      } else if (difference < 60) {
        regPercent = 60.0;
      } else if (difference <= 120) {
        regPercent = 40.0;
      } else {
        regPercent = 20.0;
      }

      totalScore += regPercent;
      count++;
    }

    return count > 0 ? totalScore / count : 0.0;
  }

  /// Restoration Score (20% weight)
  /// Based on duration and sleep timing
  static double _calculateRestorationScore(List<SleepRecordModel> records) {
    if (records.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (var record in records) {
      if (record.sleepStart == null) continue;

      final hours = record.durationMinutes / 60.0;
      final hour = record.sleepStart!.hour;
      double restPercent;

      // If duration > 7h AND sleepTime <= 01:00 → 100%
      if (hours > 7 && hour <= 1) {
        restPercent = 100.0;
      } else if (hours >= 6 && hours <= 7) {
        // If duration 6-7h → 70%
        restPercent = 70.0;
      } else if (hours < 5) {
        // If duration < 5h → 20%
        restPercent = 20.0;
      } else {
        // Other cases: interpolate based on duration
        if (hours >= 5 && hours < 6) {
          restPercent = 40.0;
        } else if (hours > 7 && hours <= 9) {
          restPercent = 90.0;
        } else {
          restPercent = 60.0;
        }
      }

      totalScore += restPercent;
    }

    return totalScore / records.length;
  }
}

